"""Command line tools for working without the GUI. See docs/TESTING.md."""
from __future__ import annotations

import argparse
import json
import sys

from bloxorz.core import rules
from bloxorz.core.level import load_level
from bloxorz.core.render import render_text

KEYS = {"w": "U", "s": "D", "a": "L", "d": "R", "tab": rules.SWITCH, "\t": rules.SWITCH}


def cmd_show(args) -> None:
    level = load_level(args.level)
    try:
        state = rules.initial_state(level)
    except NotImplementedError:
        state = None   # rules not written yet: draw the board only
    print(f"Level {level.id}: {level.name} [{level.group}]")
    print(render_text(level, state))


def cmd_play(args) -> None:
    level = load_level(args.level)
    state = rules.initial_state(level)
    moves = 0
    print("w/a/s/d = move, tab = switch cube, r = restart, q = quit (Enter after each command)")
    while True:
        print(render_text(level, state), f"\nmoves={moves}")
        key = input("> ").strip().lower() or "\t"
        if key == "q":
            return
        if key == "r":
            state, moves = rules.initial_state(level), 0
            continue
        if key not in KEYS:
            print("unknown key")
            continue
        res = rules.step(level, state, KEYS[key])
        if res.events:
            print("events:", res.events)
        if res.state is None:
            print("The block fell! Restarting.")
            state, moves = rules.initial_state(level), 0
            continue
        state, moves = res.state, moves + 1
        if rules.is_goal(level, state):
            print(render_text(level, state), f"\nYOU WIN in {moves} moves")
            return


def cmd_solve(args) -> None:
    from bloxorz.search import ALGORITHMS
    from bloxorz.search.common import run_solver

    level = load_level(args.level)
    start = rules.initial_state(level)
    result = run_solver(ALGORITHMS[args.algo], level, start, measure_memory=not args.no_memory)
    out = result.to_json(level.id, args.algo)
    print(json.dumps(out, ensure_ascii=False))
    if result.found and not rules.verify(level, result.actions):
        print("WARNING: solution does not pass verify()", file=sys.stderr)
    if args.replay and result.found:
        for i, s in enumerate(rules.apply_actions(level, result.actions)):
            print(f"\n--- step {i}" + (f" ({result.actions[i - 1]})" if i else ""))
            print(render_text(level, s))
    if args.out:
        with open(args.out, "w", encoding="utf-8") as f:
            json.dump(out, f, ensure_ascii=False, indent=2)


def cmd_verify(args) -> None:
    level = load_level(args.level)
    with open(args.result, encoding="utf-8") as f:
        actions = json.load(f)["actions"]
    ok = rules.verify(level, actions)
    print("OK" if ok else "INVALID", f"({len(actions)} actions)")
    sys.exit(0 if ok else 1)


def main(argv: list[str] | None = None) -> None:
    p = argparse.ArgumentParser(prog="python -m bloxorz")
    sub = p.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("show", help="print a level as text")
    s.add_argument("level")
    s.set_defaults(func=cmd_show)

    s = sub.add_parser("play", help="play in the terminal")
    s.add_argument("level")
    s.set_defaults(func=cmd_play)

    s = sub.add_parser("solve", help="run a solver")
    s.add_argument("level")
    s.add_argument("--algo", default="bfs", choices=["bfs", "dfs", "ucs", "astar"])
    s.add_argument("--out", help="write the result JSON here")
    s.add_argument("--replay", action="store_true", help="print the board after every action")
    s.add_argument("--no-memory", action="store_true", help="skip the tracemalloc run")
    s.set_defaults(func=cmd_solve)

    s = sub.add_parser("verify", help="check a result file against the rules")
    s.add_argument("level")
    s.add_argument("result")
    s.set_defaults(func=cmd_verify)

    args = p.parse_args(argv)
    args.func(args)
