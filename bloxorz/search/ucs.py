"""Uniform-Cost Search. Owner: thành viên UCS/A*.

Hint: heapq with (g, counter, state); skip a popped state if a cheaper g was
already settled. Step costs come from rules.successors (docs/GAME_RULES.md section 6).
"""
from __future__ import annotations

from bloxorz.core.level import Level
from bloxorz.core.state import State
from bloxorz.search.common import SearchResult


def ucs(level: Level, start: State) -> SearchResult:
    """Cheapest solution under the team's cost function."""
    raise NotImplementedError("TODO(ucs)")
