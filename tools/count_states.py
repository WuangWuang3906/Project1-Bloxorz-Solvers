"""Count the reachable states of every level (the size of each search space).

Usage (repo root):  python tools/count_states.py
Writes bloxorz/data/state_counts.json ({"<level id>": count}). The GUI shows
solver progress as "expanded / reachable states"; the report can quote the
numbers. Run again after adding or editing a level (tests/test_state_counts.py
checks they still match).
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from bloxorz.core import rules  # noqa: E402
from bloxorz.core.level import Level, load_level  # noqa: E402

OUT = ROOT / "bloxorz" / "data" / "state_counts.json"


def count_states(level: Level) -> int:
    """Number of states reachable from the start (falls excluded)."""
    start = rules.initial_state(level)
    seen = {start}
    stack = [start]
    while stack:
        state = stack.pop()
        if rules.is_goal(level, state):
            continue   # the game ends on the goal
        for _, nxt, _ in rules.successors(level, state):
            if nxt not in seen:
                seen.add(nxt)
                stack.append(nxt)
    return len(seen)


def main() -> None:
    counts = {}
    for f in sorted((ROOT / "levels").glob("level*.json")):
        level = load_level(f)
        counts[str(level.id)] = count_states(level)
        print(f"level{level.id:02d}: {counts[str(level.id)]} states", flush=True)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(counts, indent=1) + "\n", encoding="utf-8")
    print(f"wrote {OUT}")


if __name__ == "__main__":
    main()
