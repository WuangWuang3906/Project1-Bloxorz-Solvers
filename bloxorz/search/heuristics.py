"""Heuristics for A*. Owner: Pham Nguyen Quang Sang.

default_heuristic is admissible (never above the true remaining cost) but not
consistent on some split-level edges; astar.py reopens states, so A* stays optimal.
"""
from __future__ import annotations

from bloxorz.core.level import Level
from bloxorz.core.state import State, STAND, H, V, SPLIT


def zero(level: Level, state: State) -> float:
    """h = 0: A* becomes UCS. Useful as a sanity check."""
    return 0.0


def default_heuristic(level: Level, state: State) -> float:
    """Manhattan distance from the block cell nearest the goal, divided by 2,
    plus 0.5 when the block is not standing.
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
