"""Heuristics for A*. Owner: Pham Nguyen Quang Sang.

default_heuristic is admissible and consistent (checked on every reachable
state of all levels): one action costs >= 1 and moves the block centre (or the
midpoint of the two cubes) by at most 1.5 cells, so h drops by at most 1 per
action; split switches ("portals") are covered by _shortcuts.
old_heuristic is the first version, kept for comparison in the report.
"""
from __future__ import annotations

from functools import lru_cache

from bloxorz.core.level import Level
from bloxorz.core.state import State, STAND, H, V, SPLIT


def zero(level: Level, state: State) -> float:
    """h = 0: A* becomes UCS. Useful as a sanity check."""
    return 0.0


def old_heuristic(level: Level, state: State) -> float:
    """Manhattan distance from the block cell nearest the goal, divided by 2,
    plus 0.5 when the block is not standing. Admissible but not consistent
    on some split-switch moves (the cubes jump far in one action).
    """
    goal_pos = level.goal

    r, c = state.pos
    if state.orient == STAND:
        # occupy (r, c)
        min_dist = abs(r - goal_pos[0]) + abs(c - goal_pos[1])
    elif state.orient == H:
        # occupy (r, c) and (r, c+1) -> use the nearest pos
        dist1 = abs(r - goal_pos[0]) + abs(c - goal_pos[1])
        dist2 = abs(r - goal_pos[0]) + abs(c + 1 - goal_pos[1])
        min_dist = min(dist1, dist2)
    elif state.orient == V:
        # occupy (r, c) and (r+1, c) -> use the nearest pos
        dist1 = abs(r - goal_pos[0]) + abs(c - goal_pos[1])
        dist2 = abs(r + 1 - goal_pos[0]) + abs(c - goal_pos[1])
        min_dist = min(dist1, dist2)
    elif state.orient == SPLIT and state.cubes:
        # split into 2 pieces -> use the nearest pos
        c1, c2 = state.cubes
        d1 = abs(c1[0] - goal_pos[0]) + abs(c1[1] - goal_pos[1])
        d2 = abs(c2[0] - goal_pos[0]) + abs(c2[1] - goal_pos[1])
        min_dist = min(d1, d2)
    else:
        # fallback so an unexpected state never crashes the search
        min_dist = abs(r - goal_pos[0]) + abs(c - goal_pos[1])

    # Admissible: one action moves the nearest cell at most 2 squares closer
    # (a lying block rolls 2 cells at once) and every action costs >= 1.
    h_val = min_dist / 2.0

    # A block that is not standing needs at least one more action to stand on the goal.
    if state.orient != STAND:
        h_val += 0.5

    return h_val


# Cost bound after using a split switch ("portal"). Computed once per level and
# cached; the cache key is the Level object, which never changes during a search.
@lru_cache(maxsize=32)
def _shortcuts(level: Level) -> tuple[tuple[tuple[int, int], int], ...]:
    """(doubled switch point, bound to goal after standing on it) per split switch."""
    d = lambda a, b: (abs(a[0] - b[0]) + 2) // 3 + (abs(a[1] - b[1]) + 2) // 3
    goal = ((2 * level.goal[0], 2 * level.goal[1]), 0)
    sw = [
        ((2 * s.pos[0], 2 * s.pos[1]),
         (s.split_to[0][0] + s.split_to[1][0], s.split_to[0][1] + s.split_to[1][1]))
        for s in level.switches.values() if s.type == "split" and s.split_to
    ]
    t = [10**9] * len(sw)
    for _pass in range(len(sw) + 1):          # Bellman-Ford style relaxation
        for i, (_, mid) in enumerate(sw):
            t[i] = min(d(mid, p) + c for p, c in [goal] + [(sw[j][0], t[j]) for j in range(len(sw))])
    return tuple((sw[i][0], t[i]) for i in range(len(sw)))


def default_heuristic(level: Level, state: State) -> float:
    """Closed-form consistent lower bound on the remaining cost."""
    if state.orient == SPLIT and state.cubes:
        (r1, c1), (r2, c2) = state.cubes
        y, x = r1 + r2, c1 + c2                         # cube midpoint (doubled)
    else:
        y = 2 * state.pos[0] + (state.orient == V)      # block center (doubled)
        x = 2 * state.pos[1] + (state.orient == H)
    goal = ((2 * level.goal[0], 2 * level.goal[1]), 0)
    return float(min(
        (abs(y - p[0]) + 2) // 3 + (abs(x - p[1]) + 2) // 3 + after
        for p, after in [goal, *_shortcuts(level)]
    ))
