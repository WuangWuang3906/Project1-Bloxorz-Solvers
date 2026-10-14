"""Plain-text board renderer for testing without the GUI."""
from __future__ import annotations

from bloxorz.core.level import BRIDGE, FLOOR, FRAGILE, GOAL, HEAVY, SOFT, SPLIT, START, VOID, Level
from bloxorz.core.state import H, STAND, V, State

_TILES = {VOID: "  ", FLOOR: "##", START: "##", FRAGILE: "ff", GOAL: "GG", SOFT: "so", HEAVY: "hx", SPLIT: "sp"}


def block_cells(state: State) -> list[tuple[int, int]]:
    """Cells covered by the block (or both cubes)."""
    if state.is_split:
        return list(state.cubes)
    r, c = state.pos
    if state.orient == STAND:
        return [(r, c)]
    if state.orient == H:
        return [(r, c), (r, c + 1)]
    if state.orient == V:
        return [(r, c), (r + 1, c)]
    raise ValueError(f"unknown orient {state.orient}")


def render_text(level: Level, state: State | None = None) -> str:
    """Board as text; the block is drawn as [] (active cube as <> when split)."""
    covered = set(block_cells(state)) if state else set()
    active = state.cubes[state.active] if state and state.is_split else None
    lines = []
    for r, row in enumerate(level.grid):
        out = []
        for c, ch in enumerate(row):
            if (r, c) == active:
                out.append("<>")
            elif (r, c) in covered:
                out.append("[]")
            elif ch == BRIDGE:
                bid = level.bridge_at[(r, c)]
                is_open = bid in state.open_bridges if state else level.bridges[bid].open
                out.append("==" if is_open else "..")
            else:
                out.append(_TILES[ch])
        lines.append("".join(out).rstrip())
    if state:
        lines.append(f"orient={state.orient} pos={state.pos} open={sorted(state.open_bridges)}")
    return "\n".join(lines)
