"""Shared search utilities. Every solver must be measured through run_solver()."""
from __future__ import annotations

import time
import tracemalloc
from dataclasses import asdict, dataclass, field
from typing import Callable

from bloxorz.core.level import Level
from bloxorz.core.state import State


@dataclass
class SearchResult:
    found: bool
    actions: list[str] = field(default_factory=list)
    cost: float = 0.0
    expanded: int = 0          # nodes popped from the frontier and expanded
    time_ms: float = 0.0       # filled by run_solver
    peak_kb: float = 0.0       # filled by run_solver

    def to_json(self, level_id: int, algo: str) -> dict:
        """Result file format from docs/JSON_FORMAT.md section 4."""
        d = asdict(self)
        return {
            "level": level_id, "algo": algo, "found": self.found, "actions": self.actions,
            "metrics": {"time_ms": round(d["time_ms"], 3), "peak_kb": round(d["peak_kb"], 1),
                        "expanded": self.expanded, "length": len(self.actions), "cost": self.cost},
        }


Solver = Callable[[Level, State], SearchResult]


def reconstruct(parent: dict, goal: State) -> list[str]:
    """Follow parent[state] = (prev_state, action) back to the start."""
    actions = []
    s = goal
    while parent.get(s) is not None:
        s, a = parent[s]
        actions.append(a)
    actions.reverse()
    return actions


def run_solver(solver: Solver, level: Level, start: State, measure_memory: bool = True) -> SearchResult:
    """Run a solver and fill time_ms and peak_kb.

    tracemalloc slows Python down a lot, so time is measured in a first run
    without it, and peak memory in a second run with it.
    """
    t0 = time.perf_counter()
    result = solver(level, start)
    result.time_ms = (time.perf_counter() - t0) * 1000
    if measure_memory:
        tracemalloc.start()
        try:
            solver(level, start)
            _, peak = tracemalloc.get_traced_memory()
        finally:
            tracemalloc.stop()
        result.peak_kb = peak / 1024
    return result
