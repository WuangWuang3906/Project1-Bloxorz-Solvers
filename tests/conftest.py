import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from bloxorz.core.level import load_level, parse_level  # noqa: E402

LEVELS = ROOT / "levels"
HARD_LEVELS = {"level13.json", "level14.json", "level15.json"}   # big levels, seconds per solve


def pytest_configure(config):
    config.addinivalue_line("markers", 'slow: big levels 13-15; skip with -m "not slow"')


def level_params(names):
    """Parametrize values for level names; the big levels get the `slow` mark."""
    return [pytest.param(n, marks=pytest.mark.slow) if n in HARD_LEVELS else n for n in names]


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
