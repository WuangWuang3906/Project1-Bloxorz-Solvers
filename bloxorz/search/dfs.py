"""Depth-First Search (or Iterative Deepening). Owner: thành viên BFS/DFS.

Hint: use an explicit stack (no recursion: Python's recursion limit is ~1000)
and a visited set to avoid cycles (đề tr. 5 yêu cầu xử lý trạng thái lặp).
"""
from __future__ import annotations

from bloxorz.core.level import Level
from bloxorz.core.state import State
from bloxorz.search.common import SearchResult


def dfs(level: Level, start: State) -> SearchResult:
    """Any valid solution; not guaranteed to be the shortest."""
    raise NotImplementedError("TODO(dfs)")
