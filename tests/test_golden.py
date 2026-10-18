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
    "level04.json": ["R", "R", "D", "R", "R", "L", "D"],
    "level05.json": ["R", "R", "D", "D", "R", "R", "R", "U", "L", "D", "R", "U"],
    "level06.json": ["R", "U", "L", "D", "R", "D", "R", "R", "R", "R", "R", "U", "R"],
    "level07.json": ["R", "D", "R", "R", "R", "R", "R", "R", "U", "L"],
    "level08.json": ["D", "R", "U", "R", "D", "D", "R", "R", "R", "R", "U", "R"],
    "level09.json": ["R", "D", "L", "U", "R", "D", "L", "U", "U", "R", "D", "R", "R", "R", "R", "R", "R", "R", "R", "R", "D", "R", "U", "L"],
    "level10.json": ["R", "U", "L", "D", "R", "R", "R", "R", "R", "R", "R", "D", "L", "U", "R"],
    "level11.json": ["R", "U", "L", "D", "R", "R", "R", "R", "R", "R", "R", "R", "R", "R", "D", "R", "U", "L"],
    "level12.json": ["R", "U", "L", "D", "R", "R", "R", "R", "R", "D", "R", "D", "R", "R", "U", "R"],
    "level13.json": ["R", "U", "L", "D", "L", "U", "R", "D", "R", "R", "R", "R", "R"],
    "level14.json": ["R", "U", "L", "D", "R", "U", "L", "D", "R", "R", "R", "R", "R", "R", "R", "R", "R"],
    "level15.json": ["R", "U", "R", "D", "L", "U", "L", "D", "R", "R", "R", "R", "R"],
    "level16.json": ["D", "R", "U", "R", "R", "R", "R", "R", "R"],
    "level17.json": ["R", "U", "L", "D", "L", "U", "R", "D", "R", "D", "L", "SWITCH", "U", "L", "L", "R"],
    "level18.json": ["R", "R", "D", "U", "D", "D", "R", "R", "R", "R", "SWITCH", "D", "U"],
    "level19.json": ["R", "U", "L", "D", "L", "U", "R", "D", "R", "D", "R", "R", "R", "R", "U"],
    "level20.json": ["R", "U", "L", "D", "R", "R", "R", "R", "R", "R", "R", "U", "L", "D", "R", "L", "U", "R", "D", "R", "U", "L", "D", "R", "R", "R", "R", "R", "R", "R", "R", "D", "L"],
}


@pytest.mark.parametrize("name,actions", GOLDEN.items())
def test_golden_solution_is_valid(name, actions):
    assert rules.verify(load_level(LEVELS / name), actions)


@pytest.mark.parametrize("name,actions", GOLDEN.items())
def test_golden_solution_minus_last_move_is_not_a_win(name, actions):
    assert not rules.verify(load_level(LEVELS / name), actions[:-1])
