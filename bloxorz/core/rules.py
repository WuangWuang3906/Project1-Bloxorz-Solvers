"""Game rules — the single source of truth. Spec: docs/GAME_RULES.md.

TODO(core): implement every function that raises NotImplementedError.
tests/test_roll.py and tests/test_rules.py describe the expected behaviour.
"""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Iterator

from bloxorz.core.level import Level
from bloxorz.core.state import State

Pos = tuple[int, int]
ACTIONS = ("U", "D", "L", "R")
SWITCH = "SWITCH"


class IllegalMove(Exception):
    """Raised by apply_actions when an action makes the block fall."""


@dataclass
class StepResult:
    state: State | None              # None when the move is illegal (block falls)
    cost: float = 0.0
    events: list[str] = field(default_factory=list)


def roll(pos: Pos, orient: str, direction: str) -> tuple[Pos, str]:
    """Roll table only (docs/GAME_RULES.md section 2); ignores the board."""
    raise NotImplementedError("TODO(core): roll table")


def occupied_cells(state: State) -> list[Pos]:
    """Cells the block (or both cubes) covers."""
    raise NotImplementedError("TODO(core)")


def initial_state(level: Level) -> State:
    """Start state: start pos/orient and the bridges that are open at the beginning."""
    raise NotImplementedError("TODO(core)")


def step(level: Level, state: State, action: str) -> StepResult:
    """Apply one action following the order in docs/GAME_RULES.md section 3."""
    raise NotImplementedError("TODO(core)")


def successors(level: Level, state: State) -> Iterator[tuple[str, State, float]]:
    """Yield (action, next_state, cost) for every legal action."""
    raise NotImplementedError("TODO(core)")


def is_goal(level: Level, state: State) -> bool:
    """Whole block standing on the goal."""
    raise NotImplementedError("TODO(core)")


def apply_actions(level: Level, actions: list[str]) -> list[State]:
    """States after each action, starting with the initial state. Raises IllegalMove."""
    states = [initial_state(level)]
    for i, a in enumerate(actions):
        res = step(level, states[-1], a)
        if res.state is None:
            raise IllegalMove(f"action #{i} ({a}) is illegal")
        states.append(res.state)
    return states


def verify(level: Level, actions: list[str]) -> bool:
    """True when every action is legal and the last state is a goal."""
    try:
        states = apply_actions(level, actions)
    except IllegalMove:
        return False
    return is_goal(level, states[-1])
