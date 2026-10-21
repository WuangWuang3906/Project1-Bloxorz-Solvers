"""A* Search. Owner: Pham Nguyen Quang Sang.

Frontier ordered by f = g + h (heapq; ties broken by smaller h, then insertion order).
- Complete: yes on a finite state space (every action costs >= 1).
- Optimal: yes when h is admissible. h is not consistent everywhere, so a state is
  pushed again whenever a cheaper path to it is found (best_cost), no closed set.
- Time/space: O(b^d) in the worst case like UCS; a good h expands fewer nodes.
"""
from __future__ import annotations

import heapq
from itertools import count
from typing import Callable

from bloxorz.core import rules
from bloxorz.core.level import Level
from bloxorz.core.state import State
from bloxorz.search.common import SearchResult, reconstruct
from bloxorz.search.heuristics import default_heuristic, zero


def astar(
    level: Level,
    start: State,
    heuristic: Callable[[Level, State], float] | None = default_heuristic,
) -> SearchResult:
    """A* search ordered by f = g + h. Optimal when h is admissible."""
    if heuristic is None:
        heuristic = zero

    if rules.is_goal(level, start):
        return SearchResult(found=True, actions=[], cost=0.0, expanded=0)

    h_cache: dict[State, float] = {}

    def h_of(state: State) -> float:
        value = h_cache.get(state)
        if value is None:
            value = heuristic(level, state)
            h_cache[state] = value
        return value

    counter = count()
    h0 = h_of(start)
    frontier: list[tuple[float, float, int, float, State]] = [
        (h0, h0, next(counter), 0.0, start)
    ]
    best_cost: dict[State, float] = {start: 0.0}
    parent: dict[State, tuple[State, str] | None] = {start: None}
    expanded = 0

    while frontier:
        _, _, _, g, current = heapq.heappop(frontier)

        # Stale entry: a cheaper path to this state was found after it was pushed.
        if g > best_cost.get(current, float("inf")):
            continue

        if rules.is_goal(level, current):
            return SearchResult(
                found=True, actions=reconstruct(parent, current), cost=g, expanded=expanded
            )

        expanded += 1

        for action, next_state, step_cost in rules.successors(level, current):
            new_g = g + step_cost
            if new_g < best_cost.get(next_state, float("inf")):
                best_cost[next_state] = new_g
                parent[next_state] = (current, action)
                h = h_of(next_state)
                heapq.heappush(frontier, (new_g + h, h, next(counter), new_g, next_state))

    return SearchResult(found=False, actions=[], cost=0.0, expanded=expanded)
