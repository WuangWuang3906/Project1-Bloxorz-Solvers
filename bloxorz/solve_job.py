"""Background solving for the GUI server.

The solver runs in a worker process, so the server keeps answering while a big
level is being solved, and a new level / Restart can stop the search at once
(a Python thread cannot be stopped from outside; a process can).

Phases of one job: solving -> measuring -> done (or error).
"measuring" = the actions and time are known and the GUI can already replay
them; the worker is still doing the second, tracemalloc run for peak memory
(see run_solver), which takes several times longer than the search itself.

Progress: while solving, the worker counts calls to rules.successors (every
solver calls it exactly once per expanded node) and sends the count about
10 times per second. The solver files are not changed: the function is only
swapped for a counting wrapper in the worker process (~3% slower).
"""
from __future__ import annotations

import json
import multiprocessing as mp
import sys
import time
from multiprocessing.connection import Connection
from pathlib import Path

from bloxorz.core import rules
from bloxorz.core.level import Level
from bloxorz.search import ALGORITHMS
from bloxorz.search.common import measure_peak_kb, run_solver

RUNNING = ("solving", "measuring")
STATE_COUNTS = Path(__file__).with_name("data") / "state_counts.json"   # tools/count_states.py


def reachable_states(level_id: int) -> int | None:
    """Size of the level's state space, if tools/count_states.py recorded it."""
    try:
        return json.loads(STATE_COUNTS.read_text(encoding="utf-8")).get(str(level_id))
    except (OSError, ValueError):
        return None


def _count_expansions(conn: Connection):
    """Swap rules.successors for a wrapper that reports progress; returns undo()."""
    original = rules.successors
    count = 0
    last = time.perf_counter()

    def counting(level, state):
        nonlocal count, last
        count += 1
        if count & 511 == 0:
            now = time.perf_counter()
            if now - last > 0.1:
                last = now
                conn.send(("progress", count))
        return original(level, state)

    # bfs.py does `from bloxorz.core.rules import successors`, the others call
    # rules.successors: replace every reference the solver modules hold.
    patched = [rules] + [m for name, m in sys.modules.items() if name.startswith("bloxorz.search")
                         and getattr(m, "successors", None) is original]
    for m in patched:
        m.successors = counting

    def undo() -> None:
        for m in patched:
            m.successors = original

    return undo


def _worker(conn: Connection) -> None:
    """Worker process: run (algo, level) jobs until the server closes the pipe."""
    while True:
        try:
            algo, level = conn.recv()
        except (EOFError, OSError):
            return
        try:
            solver = ALGORITHMS[algo]
            start = rules.initial_state(level)
            # Same measurement as run_solver(), split in two so the GUI can
            # start the replay before the slow memory run is over.
            undo = _count_expansions(conn)
            try:
                result = run_solver(solver, level, start, measure_memory=False)
            finally:
                undo()
            conn.send(("result", result.to_json(level.id, algo)))
            conn.send(("peak", round(measure_peak_kb(solver, level, start), 1)))
        except (EOFError, OSError):
            return
        except NotImplementedError:
            conn.send(("error", f"{algo} is not implemented yet"))
        except Exception as e:  # a solver bug must not kill the worker
            conn.send(("error", f"{type(e).__name__}: {e}"))


class SolveJob:
    """At most one solve at a time for one GUI connection; start() replaces it."""

    def __init__(self) -> None:
        self._proc: mp.process.BaseProcess | None = None
        self._conn: Connection | None = None
        self.phase = "idle"
        self.result: dict | None = None
        self.error: str | None = None
        self.progress = 0             # nodes expanded so far
        self.total: int | None = None  # reachable states of the level, if known

    def warm(self) -> None:
        """Start the worker early: a new Python process needs ~0.5 s on Windows."""
        if self._proc is None or not self._proc.is_alive():
            self._drop()
            ctx = mp.get_context("spawn")
            parent, child = ctx.Pipe()
            self._proc = ctx.Process(target=_worker, args=(child,), daemon=True)
            self._proc.start()
            child.close()
            self._conn = parent

    def start(self, algo: str, level: Level) -> None:
        """Solve `level` from its initial state; cancels a solve still running."""
        self.cancel()
        self.warm()
        self._conn.send((algo, level))
        self.phase, self.result, self.error = "solving", None, None
        self.progress, self.total = 0, reachable_states(level.id)

    def poll(self) -> dict:
        """Collect what the worker has sent so far (never blocks)."""
        try:
            while self.phase in RUNNING and self._conn.poll():
                kind, data = self._conn.recv()
                if kind == "progress":
                    self.progress = data
                elif kind == "result":
                    data["metrics"]["peak_kb"] = None   # filled when "peak" arrives
                    self.result, self.phase = data, "measuring"
                    self.progress = data["metrics"]["expanded"]
                elif kind == "peak":
                    self.result["metrics"]["peak_kb"] = data
                    self.phase = "done"
                else:
                    self.error, self.phase = data, "error"
        except (EOFError, OSError):
            pass
        if self.phase in RUNNING and not self._proc.is_alive():
            self.error, self.phase = "solver process stopped (out of memory?)", "error"
            self._drop()
        return {"phase": self.phase, "result": self.result, "error": self.error,
                "progress": self.progress, "total": self.total}

    def cancel(self) -> None:
        """Stop a running solve (kills the worker, starts a fresh one)."""
        if self.phase in RUNNING:
            self._drop()
            self.warm()
        self.phase, self.result, self.error = "idle", None, None

    def close(self) -> None:
        self._drop()

    def _drop(self) -> None:
        if self._proc is not None:
            if self._proc.is_alive():
                self._proc.terminate()
            self._proc.join(timeout=2)
        if self._conn is not None:
            self._conn.close()
        self._proc = self._conn = None
