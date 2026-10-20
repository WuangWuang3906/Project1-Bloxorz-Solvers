"""Depth-First Search (or Iterative Deepening). Owner: thành viên BFS/DFS.

Hint: use an explicit stack (no recursion: Python's recursion limit is ~1000)
and a visited set to avoid cycles (đề tr. 5 yêu cầu xử lý trạng thái lặp).
"""
from __future__ import annotations

from bloxorz.core import rules
from bloxorz.core.level import Level
from bloxorz.core.state import State
from bloxorz.search.common import SearchResult, reconstruct


def dfs(level: Level, start: State) -> SearchResult:
    """Any valid solution; not guaranteed to be the shortest."""

    # Tạo danh sách parent lưu node cha để truy ngược đường đi khi đã đến đích
    parent: dict = {start: None}

    # cost_to[state] = tổng chi phí từ vạch xuất phát đến trạng thái hiện tại.
    cost_to: dict = {start: 0.0}
    stack = [start]     
    visited = set()     # Danh sách chứa những nơi đã thăm
    expanded = 0        # Đếm số trạng thái đã mở rộng/xử lý

    # Khi ngăn xếp còn trạng thái thì lặp
    while stack:
        current = stack.pop()

        # Nếu nơi hiện tại đang xét đã được thăm bỏ qua, chưa thì thêm vào visited
        if current in visited:
            continue
        visited.add(current)
        expanded += 1

        # Khối đứng trên đích thì trả kết quả
        if rules.is_goal(level, current):
            return SearchResult(
                found=True,
                actions=reconstruct(parent, current),
                cost=cost_to[current],
                expanded=expanded,
            )

        # Vòng lặp để di chuyển khối block đi tiếp và tính trạng thái theo luật
        for action, next_state, step_cost in rules.successors(level, current):
            if next_state in visited:
                continue
            # Ghi đè cha để đường tới next_state luôn là đường đang được duyệt gần nhất; cost_to phải cập nhật cùng lúc để khớp với parent.
            # cost_to cũng phải cập nhật cộng dồn cùng lúc để khớp với parent.
            parent[next_state] = (current, action)
            cost_to[next_state] = cost_to[current] + step_cost
            stack.append(next_state)

    return SearchResult(found=False, expanded=expanded)