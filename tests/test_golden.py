"""Known solutions of the sample levels (shortest number of actions).

When you add a level, add one known solution here.
"""
import pytest

from bloxorz.core import rules
from bloxorz.core.level import load_level
from conftest import LEVELS

GOLDEN = {
    "level01.json": ["R", "D", "D", "R", "R", "D", "R"],
    "level02.json": ["R", "U", "L", "D", "R", "R", "R", "R", "R", "R", "R", "R", "R", "U", "L", "D", "R"],
    "level03.json": ["R", "U", "R", "D", "L", "U", "L", "D", "R", "R", "R", "R", "R"],
}


@pytest.mark.parametrize("name,actions", GOLDEN.items())
def test_golden_solution_is_valid(name, actions):
    assert rules.verify(load_level(LEVELS / name), actions)


@pytest.mark.parametrize("name,actions", GOLDEN.items())
def test_golden_solution_minus_last_move_is_not_a_win(name, actions):
    assert not rules.verify(load_level(LEVELS / name), actions[:-1])
