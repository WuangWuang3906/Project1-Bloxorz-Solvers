"""Heuristics for A*. Owner: Pham Nguyen Quang Sang*.

Must stay admissible for the cost function in docs/GAME_RULES.md section 6
(every action costs >= 1), including split states. Explain why in the report.
"""
from __future__ import annotations

from bloxorz.core.level import Level
from bloxorz.core.state import State, STAND, H, V, SPLIT


def zero(level: Level, state: State) -> float:
    """h = 0: A* becomes UCS. Useful as a sanity check."""
    return 0.0


def default_heuristic(level: Level, state: State) -> float:
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

