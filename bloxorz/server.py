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
from bloxorz.core.level import Level, load_level
from bloxorz.core.state import State
from bloxorz.search import ALGORITHMS
from bloxorz.search.common import run_solver


class Session:
    """The level and current state of one GUI connection."""

    def __init__(self) -> None:
        self.level: Level | None = None
        self.state: State | None = None

    def handle(self, msg: dict) -> dict:
        cmd = msg.get("cmd")
        if cmd == "load":
            self.level = load_level(msg["path"])
            self.state = rules.initial_state(self.level)
            return {"ok": True, "state": self.state.to_json()}
        if self.level is None:
            return {"ok": False, "error": "no level loaded"}
        if cmd == "restart":
            self.state = rules.initial_state(self.level)
            return {"ok": True, "state": self.state.to_json()}
        if cmd == "move":
            res = rules.step(self.level, self.state, msg["action"])
            # After a fall the GUI reloads the level; keep the old state until then.
            if res.state is not None:
                self.state = res.state
            return {"ok": True, "state": res.state.to_json() if res.state else None, "events": res.events}
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
    sys.stdout.reconfigure(errors="replace")  # Windows consoles may not be UTF-8
    with Server(("127.0.0.1", args.port), Handler) as srv:
        print(f"Bloxorz server on 127.0.0.1:{args.port} (Ctrl+C to stop)", flush=True)
        try:
            srv.serve_forever()
        except KeyboardInterrupt:
            pass


if __name__ == "__main__":
    main()
