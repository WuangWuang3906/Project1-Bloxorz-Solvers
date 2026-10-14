"""Level model and JSON loader. See docs/JSON_FORMAT.md."""
from __future__ import annotations

import json
from dataclasses import dataclass, field
from pathlib import Path

Pos = tuple[int, int]

VOID, FLOOR, START, FRAGILE, GOAL, BRIDGE = "-", "#", "S", "F", "G", "B"
SOFT, HEAVY, SPLIT = "o", "X", "P"
VALID_CHARS = {VOID, FLOOR, START, FRAGILE, GOAL, BRIDGE, SOFT, HEAVY, SPLIT}


@dataclass(frozen=True)
class Bridge:
    id: str
    cells: tuple[Pos, ...]
    open: bool


@dataclass(frozen=True)
class Switch:
    id: str
    pos: Pos
    type: str                      # "soft" | "heavy" | "split"
    mode: str                      # "toggle" | "open" | "close"
    bridges: tuple[str, ...] = ()
    split_to: tuple[Pos, Pos] | None = None


@dataclass(frozen=True)
class Level:
    id: int
    name: str
    group: str
    grid: tuple[str, ...]
    start: Pos
    start_orient: str
    goal: Pos
    bridges: dict[str, Bridge] = field(hash=False)
    switches: dict[Pos, Switch] = field(hash=False)
    bridge_at: dict[Pos, str] = field(hash=False)   # cell -> bridge id

    @property
    def rows(self) -> int:
        return len(self.grid)

    @property
    def cols(self) -> int:
        return len(self.grid[0])

    def tile(self, pos: Pos) -> str:
        """Tile char at pos, or VOID when outside the grid."""
        r, c = pos
        if 0 <= r < self.rows and 0 <= c < self.cols:
            return self.grid[r][c]
        return VOID


def _pos(p) -> Pos:
    return (int(p[0]), int(p[1]))


def parse_level(data: dict) -> Level:
    """Build a Level from a parsed JSON dict and validate it."""
    grid = tuple(data["grid"])
    if len({len(row) for row in grid}) != 1:
        raise ValueError("all grid rows must have the same length")
    goals = [(r, c) for r, row in enumerate(grid) for c, ch in enumerate(row) if ch == GOAL]
    if len(goals) != 1:
        raise ValueError("level must have exactly one goal 'G'")
    bad = {ch for row in grid for ch in row} - VALID_CHARS
    if bad:
        raise ValueError(f"unknown tile chars: {sorted(bad)}")

    bridges = {
        b["id"]: Bridge(b["id"], tuple(_pos(p) for p in b["cells"]), bool(b["open"]))
        for b in data.get("bridges", [])
    }
    bridge_at = {cell: b.id for b in bridges.values() for cell in b.cells}
    for cell in bridge_at:
        if grid[cell[0]][cell[1]] != BRIDGE:
            raise ValueError(f"bridge cell {cell} is not 'B' in grid")

    switches = {}
    for s in data.get("switches", []):
        sw = Switch(
            id=s["id"], pos=_pos(s["pos"]), type=s["type"], mode=s.get("mode", "toggle"),
            bridges=tuple(s.get("bridges", [])),
            split_to=tuple(_pos(p) for p in s["split_to"]) if "split_to" in s else None,
        )
        unknown = set(sw.bridges) - bridges.keys()
        if unknown:
            raise ValueError(f"switch {sw.id} links unknown bridges {unknown}")
        switches[sw.pos] = sw

    return Level(
        id=int(data.get("id", 0)), name=data.get("name", ""), group=data.get("group", ""),
        grid=grid, start=_pos(data["start"]["pos"]), start_orient=data["start"].get("orient", "STAND"),
        goal=goals[0], bridges=bridges, switches=switches, bridge_at=bridge_at,
    )


def load_level(path: str | Path) -> Level:
    """Load a level JSON file."""
    with open(path, encoding="utf-8") as f:
        return parse_level(json.load(f))
