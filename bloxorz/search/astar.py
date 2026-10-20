"""A* Search. Owner: thành viên UCS/A*.

Hint: heapq with (f, counter, g, state); skip a popped state if a cheaper g was
already settled. Step costs come from rules.successors (docs/GAME_RULES.md section 6).
"""
from __future__ import annotations

import heapq
from itertools import count
from typing import Callable

from bloxorz.core import rules
from bloxorz.core.level import Level
from bloxorz.core.state import State
from bloxorz.search.common import SearchResult, reconstruct
from bloxorz.search.heuristics import default_heuristic


def astar(
    level: Level, 
    start: State, 
    heuristic: Callable[[Level, State], float] = default_heuristic
) -> SearchResult:
    """A* search combining g-cost and heuristic h-cost."""
    if heuristic is None:
        def default_h(lvl: Level, st: State) -> float:
            return 0.0
        heuristic = default_h

    if rules.is_goal(level, start):
        return SearchResult(found=True, actions=[], cost=0.0, expanded=0)

    counter = count()
    # Tính f cho trạng thái bắt đầu: f = g + h -> f = 0.0 + h(start)
    start_h = heuristic(level, start)
    frontier: list[tuple[float, int, float, State]] = [(start_h, next(counter), 0.0, start)]
    
    best_cost: dict[State, float] = {start: 0.0}
    parent: dict[State, tuple[State, str] | None] = {start: None}
    
    expanded = 0

    while frontier:
        f, _, g, current = heapq.heappop(frontier)

        # Nếu tìm thấy đường đi tới current tồi hơn chi phí đã ghi nhận thì bỏ qua
        if g > best_cost.get(current, float("inf")):
            continue

        if rules.is_goal(level, current):
            actions = reconstruct(parent, current)
            return SearchResult(found=True, actions=actions, cost=g, expanded=expanded)

        expanded += 1

        for action, next_state, step_cost in rules.successors(level, current):
            new_g = g + step_cost
            if new_g < best_cost.get(next_state, float("inf")):
                best_cost[next_state] = new_g
                parent[next_state] = (current, action)
                
                # Tính f_score mới cho trạng thái tiếp theo
                h = heuristic(level, next_state)
                new_f = new_g + h
                
                heapq.heappush(frontier, (new_f, next(counter), new_g, next_state))

    return SearchResult(found=False, actions=[], cost=0.0, expanded=expanded)