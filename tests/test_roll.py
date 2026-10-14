"""Roll table from docs/GAME_RULES.md section 2 (all 12 cases)."""
import pytest

from bloxorz.core.rules import roll

CASES = [
    # (pos, orient, dir) -> (new_pos, new_orient)
    ((5, 5), "STAND", "U", (3, 5), "V"),
    ((5, 5), "STAND", "D", (6, 5), "V"),
    ((5, 5), "STAND", "L", (5, 3), "H"),
    ((5, 5), "STAND", "R", (5, 6), "H"),
    ((5, 5), "H", "U", (4, 5), "H"),
    ((5, 5), "H", "D", (6, 5), "H"),
    ((5, 5), "H", "L", (5, 4), "STAND"),
    ((5, 5), "H", "R", (5, 7), "STAND"),
    ((5, 5), "V", "U", (4, 5), "STAND"),
    ((5, 5), "V", "D", (7, 5), "STAND"),
    ((5, 5), "V", "L", (5, 4), "V"),
    ((5, 5), "V", "R", (5, 6), "V"),
]


@pytest.mark.parametrize("pos,orient,d,new_pos,new_orient", CASES)
def test_roll_table(pos, orient, d, new_pos, new_orient):
    assert roll(pos, orient, d) == (new_pos, new_orient)


@pytest.mark.parametrize("orient", ["STAND", "H", "V"])
@pytest.mark.parametrize("d,back", [("U", "D"), ("D", "U"), ("L", "R"), ("R", "L")])
def test_roll_then_back_is_identity(orient, d, back):
    p, o = roll((5, 5), orient, d)
    assert roll(p, o, back) == ((5, 5), orient)
