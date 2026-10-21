"""Heuristics for A*. Owner: Pham Nguyen Quang Sang*.
"""

from __future__ import annotations

from functools import lru_cache

from bloxorz.core.level import Level
from bloxorz.core.state import State, STAND, H, V, SPLIT

Pt2 = tuple[int, int]  # doubled coordinates


def zero(level: Level, state: State) -> float:
    """h = 0: A* becomes UCS. Useful as a sanity check."""
    return 0.0


def _dist2(a: Pt2, b: Pt2) -> int:
    """Manhattan distance in doubled coordinates."""
    return abs(a[0] - b[0]) + abs(a[1] - b[1])


def _moves(d2: int) -> int:
    """Minimum number of actions to cover doubled distance d2: ceil(d2 / 3)."""
    return (d2 + 2) // 3


@lru_cache(maxsize=32)
def _teleports(level: Level) -> tuple[tuple[Pt2, float], ...]:
    """For each split switch: (doubled switch position, lower bound to goal after standing on it)."""
    goal2 = (2 * level.goal[0], 2 * level.goal[1])
    nodes: list[tuple[Pt2, Pt2]] = []
    for sw in level.switches.values():
        if sw.type == "split" and sw.split_to:
            (r1, c1), (r2, c2) = sw.split_to
            nodes.append(((2 * sw.pos[0], 2 * sw.pos[1]), (r1 + r2, c1 + c2)))

    table = [float("inf")] * len(nodes)
    changed = True
    while changed:  # values only decrease and stay >= 0, so this terminates
        changed = False
        for i, (_, mid) in enumerate(nodes):
            best = float(_moves(_dist2(mid, goal2)))
            for j, (pos_j, _) in enumerate(nodes):
                best = min(best, _moves(_dist2(mid, pos_j)) + table[j])
            if best < table[i]:
                table[i] = best
                changed = True
    return tuple((nodes[i][0], table[i]) for i in range(len(nodes)))


def _estimate(level: Level, point2: Pt2) -> float:
    """Lower bound on remaining cost from a center/midpoint, allowing split teleports."""
    goal2 = (2 * level.goal[0], 2 * level.goal[1])
    best = float(_moves(_dist2(point2, goal2)))
    for switch2, after in _teleports(level):
        best = min(best, _moves(_dist2(point2, switch2)) + after)
    return best


def _center2(state: State) -> Pt2:
    """Center of the block (or midpoint of the cubes) in doubled coordinates."""
    if state.orient == SPLIT and state.cubes:
        (r1, c1), (r2, c2) = state.cubes
        return (r1 + r2, c1 + c2)
    r, c = state.pos
    if state.orient == H:
        return (2 * r, 2 * c + 1)
    if state.orient == V:
        return (2 * r + 1, 2 * c)
    return (2 * r, 2 * c)  # STAND


def default_heuristic(level: Level, state: State) -> float:
    """Admissible lower bound on remaining cost (see module docstring)."""
    h = _estimate(level, _center2(state))
    # Not standing on the goal => at least one more action is needed.
    if state.orient != STAND:
        h = max(h, 1.0)
    return h