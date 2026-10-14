"""Breadth-First Search. Owner: thành viên BFS/DFS.

Hint: frontier = collections.deque; visited checked when a state is generated;
use bloxorz.core.rules.successors and is_goal; build the path with common.reconstruct.
"""
from __future__ import annotations

from bloxorz.core.level import Level
from bloxorz.core.state import State
from bloxorz.search.common import SearchResult


def bfs(level: Level, start: State) -> SearchResult:
    """Shortest solution in number of actions."""
    raise NotImplementedError("TODO(bfs)")
