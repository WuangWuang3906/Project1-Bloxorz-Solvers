"""TCP server for the Godot GUI (docs/ARCHITECTURE.md section 3).

One JSON object per line in both directions, 127.0.0.1 only.
Run from the repo root:  python -m bloxorz.server --port 5555
"""
from __future__ import annotations

import argparse
import json
import socketserver
import sys

from bloxorz.core import rules
from bloxorz.core.level import Level, load_level, parse_level
from bloxorz.core.state import State
from bloxorz.search import ALGORITHMS
from bloxorz.search.common import run_solver
from bloxorz.solve_job import SolveJob


class Session:
    """The level and current state of one GUI connection."""

    def __init__(self) -> None:
        self.level: Level | None = None
        self.state: State | None = None
        self.job = SolveJob()   # background solve for the GUI (solve_start/poll/cancel)

    def handle(self, msg: dict) -> dict:
        cmd = msg.get("cmd")
        if cmd == "load":
            self.job.cancel()   # a new level or Restart stops the solver at once
            # "level" = the JSON the GUI itself shows, so both sides solve the same board;
            # "path" = a level file relative to the server's folder.
            self.level = parse_level(msg["level"]) if "level" in msg else load_level(msg["path"])
            self.state = rules.initial_state(self.level)
            return {"ok": True, "state": self.state.to_json()}
        if self.level is None:
            return {"ok": False, "error": "no level loaded"}
        if cmd == "restart":
            self.job.cancel()
            self.state = rules.initial_state(self.level)
            return {"ok": True, "state": self.state.to_json()}
        if cmd == "move":
            res = rules.step(self.level, self.state, msg["action"])
            # After a fall the GUI reloads the level; keep the old state until then.
            if res.state is not None:
                self.state = res.state
            return {"ok": True, "state": res.state.to_json() if res.state else None, "events": res.events}
        if cmd == "apply":
            # Several moves at once (GUI "skip to the end" of a replay). Stops at the first fall.
            events: list[str] = []
            for action in msg.get("actions", []):
                res = rules.step(self.level, self.state, action)
                events = res.events
                if res.state is None:
                    return {"ok": True, "state": None, "events": events}
                self.state = res.state
            return {"ok": True, "state": self.state.to_json(), "events": events}
        if cmd == "solve":
            algo = msg.get("algo", "")
            if algo not in ALGORITHMS:
                return {"ok": False, "error": f"unknown algo {algo!r}"}
            start = rules.initial_state(self.level)
            try:
                result = run_solver(ALGORITHMS[algo], self.level, start)
            except NotImplementedError:
                return {"ok": False, "error": f"{algo} is not implemented yet"}
            return {"ok": True, "result": result.to_json(self.level.id, algo)}
        if cmd == "solve_start":
            # Non-blocking solve (what the GUI uses): the reply comes at once,
            # then the GUI asks "solve_poll" until the actions are there.
            algo = msg.get("algo", "")
            if algo not in ALGORITHMS:
                return {"ok": False, "error": f"unknown algo {algo!r}"}
            self.job.start(algo, self.level)
            return {"ok": True}
        if cmd == "solve_poll":
            return {"ok": True, **self.job.poll()}
        if cmd == "solve_cancel":
            self.job.cancel()
            return {"ok": True}
        return {"ok": False, "error": f"unknown cmd {cmd!r}"}


class Handler(socketserver.StreamRequestHandler):
    def handle(self) -> None:
        session = Session()
        print(f"GUI connected from {self.client_address[0]}", flush=True)
        for raw in self.rfile:
            try:
                msg = json.loads(raw)
                reply = session.handle(msg)
            except Exception as e:  # bad input must not kill the server
                msg, reply = {}, {"ok": False, "error": f"{type(e).__name__}: {e}"}
            print(f"<- {msg.get('cmd')} {msg.get('action', msg.get('algo', msg.get('path', '')))}"
                  f"  -> {'ok' if reply.get('ok') else reply.get('error')}", flush=True)
            self.wfile.write((json.dumps(reply, ensure_ascii=False) + "\n").encode("utf-8"))
        print("GUI disconnected", flush=True)


class Server(socketserver.ThreadingTCPServer):
    allow_reuse_address = True
    daemon_threads = True


def main() -> None:
    p = argparse.ArgumentParser(prog="python -m bloxorz.server")
    p.add_argument("--port", type=int, default=5555)
    args = p.parse_args()
    if sys.stdout is not None:  # None when the game starts us without a console
        sys.stdout.reconfigure(errors="replace")  # Windows consoles may not be UTF-8
    with Server(("127.0.0.1", args.port), Handler) as srv:
        print(f"Bloxorz server on 127.0.0.1:{args.port} (Ctrl+C to stop)", flush=True)
        try:
            srv.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    main()
