"""Split / merge and permanent switches (docs/GAME_RULES.md sections 4-6).

Behaviour cross-checked with public descriptions of the original game:
split (teleport) switches need a standing block and create two 1x1x1 cubes
that move one at a time, rejoin when adjacent, and cannot finish the stage;
small cubes can press soft switches but not heavy ones.
"""
from bloxorz.core import rules
from conftest import make_level

# r0  S # # P #        start (0,0); split switch at (0,3)
# r1  - - - - -
# r2  # # # # #        cubes appear at (2,0) and (2,4)
# r3  # # # # #
# r4  # # # # G
SPLIT_GRID = ["S##P#", "-----", "#####", "#####", "####G"]
SPLIT_SWITCH = {"id": "p1", "pos": [0, 3], "type": "split", "mode": "toggle",
                "bridges": [], "split_to": [[2, 0], [2, 4]]}


def split_level():
    return make_level(SPLIT_GRID, switches=[SPLIT_SWITCH])


def play(lvl, actions, state=None):
    s = state or rules.initial_state(lvl)
    for a in actions:
        res = rules.step(lvl, s, a)
        assert res.state is not None, f"{a} unexpectedly illegal from {s}"
        s = res.state
    return s


def split_state():
    lvl = split_level()
    return lvl, play(lvl, ["R", "R"])     # H (0,1),(0,2) -> STAND on (0,3)


# ---- splitting ---------------------------------------------------------

def test_standing_on_split_switch_splits_into_two_cubes():
    _, s = split_state()
    assert s.is_split
    assert s.cubes == ((2, 0), (2, 4))
    assert s.active == 0


def test_lying_on_split_switch_does_not_split():
    lvl = make_level(["S#P##", "-----", "#####", "####G"],
                     switches=[dict(SPLIT_SWITCH, pos=[0, 2])])
    s = play(lvl, ["R"])                  # H (0,1),(0,2) lies on the switch
    assert not s.is_split


def test_switch_action_changes_control_and_costs_1():
    lvl, s = split_state()
    res = rules.step(lvl, s, "SWITCH")
    assert res.state.active == 1
    assert res.state.cubes == s.cubes
    assert res.cost == 1


def test_switch_only_offered_when_split():
    lvl, s = split_state()
    whole_actions = {a for a, _, _ in rules.successors(lvl, rules.initial_state(lvl))}
    split_actions = {a for a, _, _ in rules.successors(lvl, s)}
    assert "SWITCH" not in whole_actions
    assert "SWITCH" in split_actions


def test_split_states_differ_by_active_cube():
    lvl, s = split_state()
    other = rules.step(lvl, s, "SWITCH").state
    assert s != other
    assert len({s, other}) == 2           # hashable, distinct in a visited set


# ---- moving cubes ------------------------------------------------------

def test_cube_moves_one_cell():
    lvl, s = split_state()
    s = play(lvl, ["D"], s)
    assert s.is_split and s.cubes == ((3, 0), (2, 4))


def test_cube_falling_off_the_board_is_illegal():
    lvl, s = split_state()
    assert rules.step(lvl, s, "L").state is None      # (2,-1)
    assert rules.step(lvl, s, "U").state is None      # (1,0) is void


def test_cube_on_goal_does_not_win():
    lvl, s = split_state()
    s = play(lvl, ["SWITCH", "D", "D"], s)            # cube 1: (2,4) -> (4,4) = G
    assert s.is_split and (4, 4) in s.cubes
    assert not rules.is_goal(lvl, s)


# ---- merging -----------------------------------------------------------

def test_cubes_merge_horizontally_when_adjacent():
    lvl, s = split_state()
    s = play(lvl, ["R", "R"], s)                       # cube 0 -> (2,2)
    assert s.is_split
    s = play(lvl, ["R"], s)                            # cube 0 -> (2,3), next to (2,4)
    assert (s.is_split, s.pos, s.orient) == (False, (2, 3), "H")


def test_cubes_merge_vertically_and_merged_block_can_win():
    lvl, s = split_state()
    s = play(lvl, ["D", "R", "R", "R"], s)             # cube 0 -> (3,3): diagonal, no merge
    assert s.is_split
    s = play(lvl, ["R"], s)                            # cube 0 -> (3,4), below (2,4)
    assert (s.is_split, s.pos, s.orient) == (False, (2, 4), "V")
    s = play(lvl, ["D"], s)                            # V (2,4) -> STAND (4,4) = G
    assert rules.is_goal(lvl, s)


# ---- cubes and tiles ---------------------------------------------------

def _cube_tile_level(tile, sw_type):
    # r0  S # # P # # #     split switch (0,3) -> cubes (2,0) and (0,6)
    # r1  - - - - - - -
    # r2  # T # # # B G     T = tested tile at (2,1); bridge b1 at (2,5)
    grid = ["S##P###", "-------", f"#{tile}###BG"]
    switches = [dict(SPLIT_SWITCH, split_to=[[2, 0], [0, 6]])]
    if sw_type:
        switches.append({"id": "s1", "pos": [2, 1], "type": sw_type, "mode": "open", "bridges": ["b1"]})
    lvl = make_level(grid, bridges=[{"id": "b1", "cells": [[2, 5]], "open": False}], switches=switches)
    return lvl, play(lvl, ["R", "R"])


def test_cube_presses_soft_switch():
    lvl, s = _cube_tile_level("o", "soft")
    s = play(lvl, ["R"], s)                            # cube 0 -> (2,1)
    assert "b1" in s.open_bridges


def test_cube_does_not_press_heavy_switch():
    lvl, s = _cube_tile_level("X", "heavy")
    s = play(lvl, ["R"], s)
    assert "b1" not in s.open_bridges


def test_cube_can_rest_on_fragile_tile():
    lvl, s = _cube_tile_level("F", None)
    assert rules.step(lvl, s, "R").state is not None


# ---- permanent switches -----------------------------------------------

def _permanent_level(mode, start_open):
    # S # o # B G : soft switch (0,2) controls bridge b1 at (0,4)
    return make_level(
        ["S#o#BG"],
        bridges=[{"id": "b1", "cells": [[0, 4]], "open": start_open}],
        switches=[{"id": "s1", "pos": [0, 2], "type": "soft", "mode": mode, "bridges": ["b1"]}],
    )


def test_permanent_close_stays_closed():
    lvl = _permanent_level("close", True)
    s = play(lvl, ["R"])                                # H (0,1),(0,2) presses
    assert "b1" not in s.open_bridges
    s = play(lvl, ["L", "R"], s)                        # press again
    assert "b1" not in s.open_bridges


def test_permanent_open_stays_open():
    lvl = _permanent_level("open", False)
    s = play(lvl, ["R"])
    assert "b1" in s.open_bridges
    s = play(lvl, ["L", "R"], s)
    assert "b1" in s.open_bridges
