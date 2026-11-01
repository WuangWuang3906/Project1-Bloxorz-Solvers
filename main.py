"""Entry point matching the submission layout (Source/main.py).

python main.py                                 start the TCP server the 3D GUI talks to
python main.py solve levels/level01.json --algo astar
python main.py play levels/level01.json        any other `python -m bloxorz` command
"""
from __future__ import annotations

import sys

from bloxorz import cli, server

if __name__ == "__main__":
    if len(sys.argv) > 1:
        cli.main(sys.argv[1:])
    else:
        server.main()
