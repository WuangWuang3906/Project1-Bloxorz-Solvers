"""Search state. Must stay hashable: it is used as a key in visited sets."""
from __future__ import annotations

from dataclasses import dataclass

Pos = tuple[int, int]

STAND, H, V, SPLIT = "STAND", "H", "V", "SPLIT"


@dataclass(frozen=True)
class State:
    pos: Pos                                  # anchor (top/left) of the whole block; cube 0 when split
    orient: str                               # STAND | H | V | SPLIT
    open_bridges: frozenset[str] = frozenset()
    cubes: tuple[Pos, Pos] | None = None      # only when orient == SPLIT
    active: int = 0                           # controlled cube when split

    @property
    def is_split(self) -> bool:
        return self.orient == SPLIT

    def to_json(self) -> dict:
        """State as described in docs/JSON_FORMAT.md section 3."""
        bridges = sorted(self.open_bridges)
        if self.is_split:
            return {"mode": "split", "cubes": [list(c) for c in self.cubes],
                    "active": self.active, "open_bridges": bridges}
        return {"mode": "whole", "pos": list(self.pos), "orient": self.orient, "open_bridges": bridges}
