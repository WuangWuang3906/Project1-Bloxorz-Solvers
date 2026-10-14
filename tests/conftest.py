import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from bloxorz.core.level import load_level, parse_level  # noqa: E402

LEVELS = ROOT / "levels"


@pytest.fixture
def level01():
    return load_level(LEVELS / "level01.json")


def make_level(grid, start=None, bridges=(), switches=(), orient="STAND"):
    """Small inline level for rule tests. start defaults to the 'S' cell."""
    if start is None:
        start = next((r, c) for r, row in enumerate(grid) for c, ch in enumerate(row) if ch == "S")
    return parse_level({
        "id": 0, "grid": list(grid), "start": {"pos": list(start), "orient": orient},
        "bridges": list(bridges), "switches": list(switches),
    })
