"""TCP server for the Godot GUI. Owner: thành viên tích hợp.

Protocol: docs/ARCHITECTURE.md section 3 (one JSON object per line, 127.0.0.1 only).
Run: python -m bloxorz.server --port 5555

TODO(server): socketserver.StreamRequestHandler; keep (level, state) per
connection; handle load / move / restart / solve; reply {"ok": false, "error": ...}
on bad input instead of crashing.
"""
from __future__ import annotations


def main() -> None:
    raise NotImplementedError("TODO(server)")


if __name__ == "__main__":
    main()
