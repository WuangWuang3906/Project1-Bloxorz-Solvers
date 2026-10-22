"""Why does a move ending on a fragile tile cost 2? Try other weights and see.

Run from the repo root:
    python benchmark/cost_weights.py
    python benchmark/cost_weights.py --weights 1 1.5 2 3 5 10 --levels 4 5 6 12

For every level with fragile tiles and every weight w, UCS is run with
"move ending on a fragile tile costs w" (everything else costs 1, as in
docs/GAME_RULES.md section 6). The rules are NOT changed: the script only
swaps rules._cost inside this process.

Recorded per (level, w): solution length, how many moves end on a fragile
tile, the path's cost under w, and nodes expanded. w = 1 is BFS-like
(fewest moves). Outputs results/cost_weights.csv and results/cost_weights.md.
"""
from __future__ import annotations

import argparse
import csv
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from bloxorz.core import rules  # noqa: E402
from bloxorz.core.level import load_level  # noqa: E402
from bloxorz.search.ucs import ucs  # noqa: E402

FIELDS = ["level", "name", "weight", "length", "fragile_moves", "cost", "expanded"]
ORIGINAL_COST = rules._cost


def on_fragile(level, state) -> bool:
    return any(level.tile(c) == rules.FRAGILE for c in rules.occupied_cells(state))


def with_weight(w: float):
    """Cost function: 1 per action, w if the action ends on a fragile tile."""
    def cost(level, state) -> float:
        return w if on_fragile(level, state) else 1.0
    return cost


def fragile_moves(level, actions: list[str]) -> int:
    """How many moves of the solution end with the block on a fragile tile."""
    states = rules.apply_actions(level, actions)
    return sum(1 for s, a in zip(states[1:], actions) if a != rules.SWITCH and on_fragile(level, s))


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--weights", nargs="+", type=float, default=[1, 1.5, 2, 3, 5, 10])
    p.add_argument("--levels", nargs="+", type=int, default=None, help="level ids (default: all with fragile tiles)")
    args = p.parse_args()

    files = sorted((ROOT / "levels").glob("level*.json"))
    rows = []
    try:
        for f in files:
            level = load_level(f)
            if args.levels and level.id not in args.levels:
                continue
            if not args.levels and not any("F" in row for row in level.grid):
                continue
            for w in args.weights:
                rules._cost = with_weight(w)
                res = ucs(level, rules.initial_state(level))
                rows.append({"level": level.id, "name": level.name, "weight": w,
                             "length": len(res.actions), "fragile_moves": fragile_moves(level, res.actions),
                             "cost": res.cost, "expanded": res.expanded})
                r = rows[-1]
                print(f"level{level.id:02d} w={w:<4g} len={r['length']:3d} fragile={r['fragile_moves']:2d} "
                      f"cost={r['cost']:g} exp={r['expanded']}", flush=True)
    finally:
        rules._cost = ORIGINAL_COST

    out = ROOT / "results" / "cost_weights.csv"
    out.parent.mkdir(parents=True, exist_ok=True)
    with out.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=FIELDS)
        w.writeheader()
        w.writerows(rows)

    lines = ["# UCS với các trọng số ô dễ vỡ", "",
             "Mỗi ô: độ dài lời giải / số nước kết thúc trên ô dễ vỡ (chi phí theo trọng số đó).", "",
             "| Màn | " + " | ".join(f"w = {w:g}" for w in args.weights) + " |",
             "| --- | " + " | ".join("---" for _ in args.weights) + " |"]
    for lid in sorted({r["level"] for r in rows}):
        rs = [r for r in rows if r["level"] == lid]
        cells = [f"{r['length']} / {r['fragile_moves']} ({r['cost']:g})" for r in rs]
        lines.append(f"| {lid:02d} {rs[0]['name']} | " + " | ".join(cells) + " |")
    out.with_suffix(".md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"\nWrote {out} and {out.with_suffix('.md')}")


if __name__ == "__main__":
    main()
