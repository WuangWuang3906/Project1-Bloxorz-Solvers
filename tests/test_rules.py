"""Board rules from docs/GAME_RULES.md sections 1, 3, 4, 6.

Coordinates are (row, col). Each test level is one or a few rows; the start
cell is 'S'. TODO(tests): split / merge / permanent "close" switches.
"""
from bloxorz.core import rules
from conftest import make_level


def costs(lvl, state):
    return {a: c for a, _, c in rules.successors(lvl, state)}


# ---- basic board -------------------------------------------------------

def test_initial_state(level01):
    s = rules.initial_state(level01)
    assert (s.pos, s.orient, s.is_split) == ((1, 1), "STAND", False)


def test_falling_off_the_board_is_illegal():
    lvl = make_level(["S##G"])
    s = rules.initial_state(lvl)
    assert rules.step(lvl, s, "U").state is None     # V at rows -2..-1
    assert rules.step(lvl, s, "L").state is None     # H at cols -2..-1


def test_half_over_void_is_illegal():
    lvl = make_level(["S#-#G"])
    # STAND (0,0) -R-> H (0,1),(0,2); (0,2) is void
    assert rules.step(lvl, rules.initial_state(lvl), "R").state is None


def test_win_only_when_standing_on_goal():
    lvl = make_level(["S##G#"])
    s = rules.step(lvl, rules.initial_state(lvl), "R").state   # H (0,1),(0,2)
    assert not rules.is_goal(lvl, s)
    s = rules.step(lvl, s, "R").state                          # STAND (0,3) = goal
    assert rules.is_goal(lvl, s)


def test_lying_across_goal_is_not_a_win():
    lvl = make_level(["##SG#"])
    s = rules.step(lvl, rules.initial_state(lvl), "R").state   # H (0,3),(0,4)
    assert s is not None and not rules.is_goal(lvl, s)


def test_successors_only_yield_legal_moves():
    lvl = make_level(["S##G"])
    assert set(costs(lvl, rules.initial_state(lvl))) == {"R"}


# ---- fragile -----------------------------------------------------------

def test_standing_on_fragile_is_illegal():
    lvl = make_level(["S##F#G"])
    s = rules.step(lvl, rules.initial_state(lvl), "R").state   # H (0,1),(0,2)
    assert rules.step(lvl, s, "R").state is None               # STAND (0,3) on F


def test_lying_on_fragile_is_legal_and_costs_2():
    lvl = make_level(["S#FF#G"])
    s0 = rules.initial_state(lvl)
    assert rules.step(lvl, s0, "R").state is not None          # H (0,1),(0,2): (0,2) is F
    assert costs(lvl, s0)["R"] == 2


def test_normal_roll_costs_1():
    lvl = make_level(["S##G"])
    assert costs(lvl, rules.initial_state(lvl))["R"] == 1


# ---- bridges and switches ---------------------------------------------

def test_closed_bridge_behaves_like_void():
    lvl = make_level(["S#BB#G"], bridges=[{"id": "b1", "cells": [[0, 2], [0, 3]], "open": False}])
    # H (0,1),(0,2): (0,2) is a closed bridge
    assert rules.step(lvl, rules.initial_state(lvl), "R").state is None


def test_open_bridge_behaves_like_floor():
    lvl = make_level(["S#BB#G"], bridges=[{"id": "b1", "cells": [[0, 2], [0, 3]], "open": True}])
    s = rules.initial_state(lvl)
    assert s.open_bridges == frozenset({"b1"})
    assert rules.step(lvl, s, "R").state is not None


def test_soft_switch_activated_by_lying_block():
    lvl = make_level(
        ["S#o#BB##G"],
        bridges=[{"id": "b1", "cells": [[0, 4], [0, 5]], "open": False}],
        switches=[{"id": "s1", "pos": [0, 2], "type": "soft", "mode": "toggle", "bridges": ["b1"]}],
    )
    res = rules.step(lvl, rules.initial_state(lvl), "R")       # H (0,1),(0,2) lies on switch
    assert res.state is not None and "b1" in res.state.open_bridges


def test_heavy_switch_activated_only_when_standing():
    bridge = [{"id": "b1", "cells": [[0, 5]], "open": False}]
    standing = make_level(["S##X#BG"], bridges=bridge,
                          switches=[{"id": "x1", "pos": [0, 3], "type": "heavy", "mode": "open", "bridges": ["b1"]}])
    s = rules.step(standing, rules.initial_state(standing), "R").state   # H (0,1),(0,2)
    s = rules.step(standing, s, "R").state                               # STAND (0,3) on heavy
    assert "b1" in s.open_bridges

    bridge2 = [{"id": "b1", "cells": [[0, 4]], "open": False}]
    lying = make_level(["S#X#BG"], bridges=bridge2,
                       switches=[{"id": "x1", "pos": [0, 2], "type": "heavy", "mode": "open", "bridges": ["b1"]}])
    s = rules.step(lying, rules.initial_state(lying), "R").state         # H (0,1),(0,2) lies on heavy
    assert s is not None and "b1" not in s.open_bridges


def test_toggle_switch_toggles_on_every_activation():
    lvl = make_level(
        ["#o##",
         "S###",
         "B##G"],
        bridges=[{"id": "b1", "cells": [[2, 0]], "open": False}],
        switches=[{"id": "s1", "pos": [0, 1], "type": "soft", "mode": "toggle", "bridges": ["b1"]}],
    )
    s = rules.step(lvl, rules.initial_state(lvl), "R").state   # H (1,1),(1,2)
    s = rules.step(lvl, s, "U").state                          # H (0,1),(0,2): on switch
    assert "b1" in s.open_bridges
    s = rules.step(lvl, s, "D").state                          # H (1,1),(1,2)
    s = rules.step(lvl, s, "U").state                          # on switch again
    assert "b1" not in s.open_bridges


def test_bridge_closing_under_the_block_makes_it_fall():
    lvl = make_level(
        ["SoB##G"],
        bridges=[{"id": "b1", "cells": [[0, 2]], "open": True}],
        switches=[{"id": "s1", "pos": [0, 1], "type": "soft", "mode": "toggle", "bridges": ["b1"]}],
    )
    # H (0,1),(0,2): presses the switch, which closes the bridge it lies on
    assert rules.step(lvl, rules.initial_state(lvl), "R").state is None
