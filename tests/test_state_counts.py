"""bloxorz/data/state_counts.json must match the levels (rerun tools/count_states.py)."""
import json
import sys
from pathlib import Path

import pytest

from bloxorz.core.level import load_level
from conftest import LEVELS, ROOT, level_params

sys.path.insert(0, str(ROOT / "tools"))
from count_states import OUT, count_states  # noqa: E402

COUNTS = json.loads(OUT.read_text(encoding="utf-8"))


@pytest.mark.parametrize("name", level_params(sorted(p.name for p in LEVELS.glob("level*.json"))))
def test_state_count_is_up_to_date(name):
    level = load_level(LEVELS / name)
    assert COUNTS.get(str(level.id)) == count_states(level)
