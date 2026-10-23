"""Heuristics for A*. Owner: Pham Nguyen Quang Sang*.
"""
from __future__ import annotations

from functools import lru_cache

from bloxorz.core.level import Level
from bloxorz.core.state import State, STAND, H, V, SPLIT


def zero(level: Level, state: State) -> float:
    """h = 0: A* becomes UCS. Useful as a sanity check."""
    return 0.0


def old_heuristic(level: Level, state: State) -> float:
    """
    Rules: Use mahattan /2 
    Add more if orientation != standing
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
        # temporary val -> avoid of crashing program
        min_dist = abs(r - goal_pos[0]) + abs(c - goal_pos[1])
    """
    ensure admissible attribute: mahattan is the fastest way with velocity = 1
    , but rectangular box can have velocity = 2 if its in V, H states
    """
    h_val = min_dist / 2.0
    
    # In case, rectangular box is nearby goal but is not stand -> can not finish in one step
    # Add a little punishment
    if state.orient != STAND:
        h_val += 0.5
        
    return h_val

"""
Function used for calculating cost after using Portal
"""
@lru_cache(maxsize=32) #Cache the result
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