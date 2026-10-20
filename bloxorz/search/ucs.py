"""Uniform-Cost Search. Owner: thành viên UCS/A*.

Hint: heapq with (g, counter, state); skip a popped state if a cheaper g was
already settled. Step costs come from rules.successors (docs/GAME_RULES.md section 6).
"""
from __future__ import annotations

import heapq
from itertools import count

from bloxorz.core import rules
from bloxorz.core.level import Level
from bloxorz.core.state import State
from bloxorz.search.common import SearchResult, reconstruct


def ucs(level: Level, start: State) -> SearchResult:
    """Cheapest solution under the team's cost function."""
    if rules.is_goal(level, start):
        return SearchResult(found=True, actions=[], cost=0.0, expanded=0)

    counter = count()
    frontier: list[tuple[float, int, State]] = [(0.0, next(counter), start)]
    
    best_cost: dict[State, float] = {start: 0.0}
    
    parent: dict[State, tuple[State, str] | None] = {start: None}
    
    expanded = 0

    while frontier:
        g, _, current = heapq.heappop(frontier)

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
                heapq.heappush(frontier, (new_g, next(counter), next_state))

    return SearchResult(found=False, actions=[], cost=0.0, expanded=expanded)