"""Cross-checks between the four solvers (docs/TESTING.md section 3)."""
import pytest

from bloxorz.core import rules
from bloxorz.core.level import load_level
from bloxorz.search import ALGORITHMS
from conftest import LEVELS, level_params
from test_golden import GOLDEN


def solve(algo, name):
    level = load_level(LEVELS / name)
    return level, ALGORITHMS[algo](level, rules.initial_state(level))


@pytest.mark.parametrize("algo", sorted(ALGORITHMS))
@pytest.mark.parametrize("name", level_params(sorted(GOLDEN)))
def test_solution_is_valid(algo, name):
    level, res = solve(algo, name)
    assert res.found
    assert rules.verify(level, res.actions)
    assert res.expanded > 0


@pytest.mark.parametrize("name", level_params(sorted(GOLDEN)))
def test_bfs_is_shortest(name):
    _, res = solve("bfs", name)
    assert len(res.actions) == len(GOLDEN[name])


@pytest.mark.parametrize("name", level_params(sorted(GOLDEN)))
def test_astar_matches_ucs_cost(name):
    _, u = solve("ucs", name)
    _, a = solve("astar", name)
    assert a.cost == u.cost


def test_unsolvable_level_returns_not_found():
    from conftest import make_level
    level = make_level(["S#-#G"])
    for algo, fn in ALGORITHMS.items():
        assert not fn(level, rules.initial_state(level)).found, algo


@pytest.mark.parametrize("name", ["level06.json"])
def test_ucs_takes_longer_but_cheaper_path_than_bfs(name):
    """Level 06: a short route over fragile tiles vs a longer solid detour."""
    _, b = solve("bfs", name)
    _, u = solve("ucs", name)
    assert len(u.actions) > len(b.actions)
    assert u.cost < b.cost
