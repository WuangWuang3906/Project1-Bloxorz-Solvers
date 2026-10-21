"""Game rules — the single source of truth. Spec: docs/GAME_RULES.md.

Every solver, the TCP server and the benchmark call these functions; nobody
else re-implements the rules.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Iterator

from bloxorz.core.level import BRIDGE, FRAGILE, VOID, Level
from bloxorz.core.state import H, SPLIT, STAND, V, State

Pos = tuple[int, int]
ACTIONS = ("U", "D", "L", "R")
SWITCH = "SWITCH"

DELTA = {"U": (-1, 0), "D": (1, 0), "L": (0, -1), "R": (0, 1)}

# (orient, direction) -> (row offset, col offset, new orient); GAME_RULES.md section 2.
ROLL_TABLE = {
    STAND: {"U": (-2, 0, V), "D": (1, 0, V), "L": (0, -2, H), "R": (0, 1, H)},
    H: {"U": (-1, 0, H), "D": (1, 0, H), "L": (0, -1, STAND), "R": (0, 2, STAND)},
    V: {"U": (-1, 0, STAND), "D": (2, 0, STAND), "L": (0, -1, V), "R": (0, 1, V)},
}


class IllegalMove(Exception):
    """Raised by apply_actions when an action makes the block fall."""


@dataclass
class StepResult:
    state: State | None              # None when the move is illegal (block falls)
    cost: float = 0.0
    events: list[str] = field(default_factory=list)


def roll(pos: Pos, orient: str, direction: str) -> tuple[Pos, str]:
    """Roll table only (docs/GAME_RULES.md section 2); ignores the board."""
    dr, dc, new_orient = ROLL_TABLE[orient][direction]
    return (pos[0] + dr, pos[1] + dc), new_orient


def _cells(pos: Pos, orient: str) -> list[Pos]:
    r, c = pos
    if orient == STAND:
        return [(r, c)]
    if orient == H:
        return [(r, c), (r, c + 1)]
    return [(r, c), (r + 1, c)]


def occupied_cells(state: State) -> list[Pos]:
    """Cells the block (or both cubes) covers."""
    if state.is_split:
        return list(state.cubes)
    return _cells(state.pos, state.orient)


def initial_state(level: Level) -> State:
    """Start state: start pos/orient and the bridges that are open at the beginning."""
    open_bridges = frozenset(b.id for b in level.bridges.values() if b.open)
    return State(level.start, level.start_orient, open_bridges)


def _cell_ok(level: Level, cell: Pos, standing: bool, open_bridges: frozenset[str]) -> bool:
    """Can this cell hold the block? Standing weight breaks fragile tiles."""
    tile = level.tile(cell)
    if tile == VOID:
        return False
    if tile == BRIDGE and level.bridge_at[cell] not in open_bridges:
        return False
    if tile == FRAGILE and standing:
        return False
    return True


def _supported(level: Level, cells: list[Pos], standing: bool, open_bridges: frozenset[str]) -> bool:
    return all(_cell_ok(level, c, standing, open_bridges) for c in cells)


def _press_switches(level: Level, cells: list[Pos], weight: str, open_bridges: frozenset[str],
                    events: list[str]) -> tuple[frozenset[str], tuple[Pos, Pos] | None]:
    """Activate switches under `cells`. weight: "stand" | "lie" | "cube".

    Returns the new open-bridge set and, if a split switch fired, the two cube cells.
    """
    opened = set(open_bridges)
    split_to = None
    for cell in cells:
        sw = level.switches.get(cell)
        if sw is None or (sw.type != "soft" and weight != "stand"):
            continue
        for bid in sw.bridges:
            was_open = bid in opened
            if sw.mode == "toggle":
                opened ^= {bid}
            elif sw.mode == "open":
                opened.add(bid)
            else:
                opened.discard(bid)
            if (bid in opened) != was_open:
                events.append(f"bridge:{bid}:{'open' if bid in opened else 'close'}")
        if sw.type == "split" and sw.split_to:
            split_to = sw.split_to
    return frozenset(opened), split_to


def _cost(level: Level, state: State) -> float:
    """1 per action, 2 if the block ends lying on a fragile tile (section 6)."""
    return 2.0 if any(level.tile(c) == FRAGILE for c in occupied_cells(state)) else 1.0


def step(level: Level, state: State, action: str) -> StepResult:
    """Apply one action following the order in docs/GAME_RULES.md section 3."""
    if state.is_split:
        return _step_split(level, state, action)
    if action == SWITCH:
        return StepResult(None, 0.0, ["invalid"])

    pos, orient = roll(state.pos, state.orient, action)
    cells = _cells(pos, orient)
    standing = orient == STAND
    if not _supported(level, cells, standing, state.open_bridges):
        return StepResult(None, 0.0, ["fall"])

    events: list[str] = []
    open_bridges, split_to = _press_switches(level, cells, "stand" if standing else "lie",
                                             state.open_bridges, events)
    if not _supported(level, cells, standing, open_bridges):
        return StepResult(None, 0.0, events + ["fall"])

    if split_to is not None:
        events.append("split")
        new = State(split_to[0], SPLIT, open_bridges, (split_to[0], split_to[1]), 0)
    else:
        new = State(pos, orient, open_bridges)
    if is_goal(level, new):
        events.append("win")
    return StepResult(new, _cost(level, new), events)


def _step_split(level: Level, state: State, action: str) -> StepResult:
    """One action while the block is split into two unit cubes (section 5)."""
    a = state.active
    if action == SWITCH:
        return StepResult(State(state.pos, SPLIT, state.open_bridges, state.cubes, 1 - a), 1.0, ["switch"])

    cubes = list(state.cubes)
    dr, dc = DELTA[action]
    target = (cubes[a][0] + dr, cubes[a][1] + dc)
    if target == cubes[1 - a] or not _cell_ok(level, target, False, state.open_bridges):
        return StepResult(None, 0.0, ["fall"])

    events: list[str] = []
    open_bridges, _ = _press_switches(level, [target], "cube", state.open_bridges, events)
    cubes[a] = target
    if not _supported(level, cubes, False, open_bridges):
        return StepResult(None, 0.0, events + ["fall"])

    (r0, c0), (r1, c1) = sorted(cubes)
    if abs(r0 - r1) + abs(c0 - c1) == 1:
        events.append("merge")
        new = State((r0, c0), H if r0 == r1 else V, open_bridges)
    else:
        new = State(cubes[0], SPLIT, open_bridges, (cubes[0], cubes[1]), a)
    return StepResult(new, _cost(level, new), events)


def successors(level: Level, state: State) -> Iterator[tuple[str, State, float]]:
    """Yield (action, next_state, cost) for every legal action."""
    actions = ACTIONS + (SWITCH,) if state.is_split else ACTIONS
    for action in actions:
        res = step(level, state, action)
        if res.state is not None:
            yield action, res.state, res.cost


def is_goal(level: Level, state: State) -> bool:
    """Whole block standing on the goal."""
    return not state.is_split and state.orient == STAND and state.pos == level.goal


def apply_actions(level: Level, actions: list[str]) -> list[State]:
    """States after each action, starting with the initial state. Raises IllegalMove."""
    states = [initial_state(level)]
    for i, a in enumerate(actions):
        res = step(level, states[-1], a)
        if res.state is None:
            raise IllegalMove(f"action #{i} ({a}) is illegal")
        states.append(res.state)
    return states


def verify(level: Level, actions: list[str]) -> bool:
    """True when every action is legal and the last state is a goal."""
    try:
        states = apply_actions(level, actions)
    except IllegalMove:
        return False
    return is_goal(level, states[-1])
