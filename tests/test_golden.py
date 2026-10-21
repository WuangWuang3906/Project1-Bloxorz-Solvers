"""Known solutions of the sample levels (shortest number of actions).

When you add a level, add one known solution here.
"""
import pytest

from bloxorz.core import rules
from bloxorz.core.level import load_level
from conftest import LEVELS

GOLDEN = {
    "level01.json": ["R", "D", "D", "R", "R", "D", "R"],
    "level02.json": ["R", "R", "D", "D", "R", "R", "R", "U", "L", "D", "R", "U"],
    "level03.json": ["D", "R", "U", "R", "D", "D", "R", "R", "R", "R", "U", "R"],
    "level04.json": ["R", "U", "L", "D", "R", "R", "R", "R", "R", "R", "R", "R", "R", "U", "L", "D", "R"],
    "level05.json": ["R", "U", "L", "D", "R", "R", "R", "R", "R", "D", "R", "D", "R", "R", "U", "R"],
    "level06.json": ["R", "U", "L", "D", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "U", "L", "D", "R"],
    "level07.json": ["R", "U", "R", "D", "L", "U", "L", "D", "R", "R", "R", "R", "R"],
    "level08.json": ["R", "U", "L", "D", "R", "U", "L", "D", "R", "R", "R", "R", "R", "R", "R", "R", "R"],
    "level09.json": ["D", "R", "U", "R", "R", "R", "R", "R", "R"],
    "level10.json": ["R", "R", "D", "R", "R", "L", "D"],
    "level11.json": ["R", "R", "D", "U", "D", "D", "R", "R", "R", "R", "SWITCH", "D", "U"],
    "level12.json": ["R", "U", "L", "D", "R", "R", "R", "R", "R", "R", "R", "U", "L", "D", "R", "L", "U", "R", "D", "R", "U", "L", "D", "R", "R", "R", "R", "R", "R", "R", "R", "D", "L"],
    "level13.json": ["R", "R", "R", "R", "R", "R", "U", "U", "R", "R", "R", "R", "D", "D", "R", "D", "R", "R", "U", "U", "U", "R", "R", "R", "U", "U", "U", "U", "U", "U", "R", "R", "R", "U", "R"],
    "level14.json": ["R", "U", "L", "D", "L", "U", "R", "D", "R", "U", "U", "L", "L", "D", "D", "D", "D", "D", "R", "R", "R", "R", "R", "R", "R", "R", "D", "D", "D", "SWITCH", "D", "D", "L", "L", "U", "U", "U", "U", "U", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "U", "R", "R"],
    "level15.json": ["R", "R", "R", "R", "R", "R", "U", "U", "R", "R", "R", "R", "D", "R", "D", "R", "D", "R", "U", "R", "U", "R", "R", "R", "R", "U", "U", "L", "L", "D", "D", "D", "D", "D", "R", "R", "R", "R", "R", "R", "R", "R", "R", "D", "D", "D", "D", "SWITCH", "D", "D", "L", "L", "U", "U", "U", "U", "U", "R", "R", "R", "R", "R", "R", "R", "R", "R", "U", "U", "R", "U", "R", "R"],
}


@pytest.mark.parametrize("name,actions", GOLDEN.items())
def test_golden_solution_is_valid(name, actions):
    assert rules.verify(load_level(LEVELS / name), actions)


@pytest.mark.parametrize("name,actions", GOLDEN.items())
def test_golden_solution_minus_last_move_is_not_a_win(name, actions):
    assert not rules.verify(load_level(LEVELS / name), actions[:-1])
