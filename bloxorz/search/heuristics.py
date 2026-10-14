"""Heuristics for A*. Owner: thành viên UCS/A*.

Must stay admissible for the cost function in docs/GAME_RULES.md section 6
(every action costs >= 1), including split states. Explain why in the report.
"""
from __future__ import annotations

from bloxorz.core.level import Level
from bloxorz.core.state import State


def zero(level: Level, state: State) -> float:
    """h = 0: A* becomes UCS. Useful as a sanity check."""
    return 0.0


def default_heuristic(level: Level, state: State) -> float:
    """TODO(astar): e.g. Manhattan distance to the goal / 2, plus an orientation term."""
    raise NotImplementedError("TODO(heuristic)")
