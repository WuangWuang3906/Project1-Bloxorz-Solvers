"""A* Search. Owner: thành viên UCS/A*.

Priority f = g + h. With a consistent heuristic, a closed set is safe.
"""
from __future__ import annotations

from bloxorz.core.level import Level
from bloxorz.core.state import State
from bloxorz.search.common import SearchResult
from bloxorz.search.heuristics import default_heuristic


def astar(level: Level, start: State, heuristic=default_heuristic) -> SearchResult:
    """Cheapest solution, guided by an admissible heuristic."""
    raise NotImplementedError("TODO(astar)")
