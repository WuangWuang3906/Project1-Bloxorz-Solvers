import pytest

from bloxorz.core.level import load_level
from conftest import LEVELS, make_level


def test_all_level_files_load():
    files = sorted(LEVELS.glob("level*.json"))
    assert files, "no level files found"
    for f in files:
        level = load_level(f)
        assert level.tile(level.start) != "-", f"{f.name}: start is on void"


def test_level01_fields(level01):
    assert level01.start == (1, 1)
    assert level01.goal == (4, 7)
    assert level01.tile((0, 3)) == "-"
    assert level01.tile((-1, 0)) == "-"     # outside the grid counts as void


def test_rejects_ragged_grid():
    with pytest.raises(ValueError):
        make_level(["S##", "##G#"])


def test_rejects_bridge_not_marked_B():
    with pytest.raises(ValueError):
        make_level(["S##G"], bridges=[{"id": "b1", "cells": [[0, 1]], "open": False}])
