"""Run every level x every algorithm without the GUI and write a CSV for the report.

Run from the repo root:
    python benchmark/run_benchmark.py
    python benchmark/run_benchmark.py --repeats 5 --timeout 300 --algos bfs ucs

Measurement (write this in the report's method section):
- time_ms: median of --repeats runs, measured with time.perf_counter and
  WITHOUT tracemalloc (it slows Python down).
- peak_kb: peak traced memory of one extra run under tracemalloc.
- expanded: as counted by each solver (nodes popped from the frontier and
  expanded; the goal node is not counted) - docs/ARCHITECTURE.md.
- length: number of actions (SWITCH included); cost: team cost function.
- Each (level, algorithm) runs in its own process with a --timeout safety cap,
  so one hard level cannot block the whole run.

Outputs: results/benchmark.csv and results/summary.md (averages per level group).
Charts: python benchmark/plot_results.py
"""
from __future__ import annotations

import argparse
import csv
import multiprocessing as mp
import platform
import statistics
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from bloxorz.core import rules  # noqa: E402
from bloxorz.core.level import load_level  # noqa: E402
from bloxorz.search import ALGORITHMS  # noqa: E402
from bloxorz.search.common import run_solver  # noqa: E402

FIELDS = ["level", "name", "group", "algo", "status", "length", "cost",
          "expanded", "time_ms", "peak_kb", "valid"]
GROUP_ORDER = ["basic", "fragile", "switch", "split"]


def measure(level_path: str, algo: str, repeats: int, out: mp.Queue) -> None:
    """Child process: solve one level with one algorithm and report the numbers."""
    try:
        level = load_level(level_path)
        start = rules.initial_state(level)
        solver = ALGORITHMS[algo]
        times = []
        result = None
        for _ in range(repeats):
            result = run_solver(solver, level, start, measure_memory=False)
            times.append(result.time_ms)
        peak = run_solver(solver, level, start, measure_memory=True).peak_kb
        out.put({
            "status": "ok" if result.found else "no_solution",
            "length": len(result.actions) if result.found else "",
            "cost": result.cost if result.found else "",
            "expanded": result.expanded,
            "time_ms": round(statistics.median(times), 3),
            "peak_kb": round(peak, 1),
            "valid": rules.verify(level, result.actions) if result.found else "",
        })
    except NotImplementedError:
        out.put({"status": "not_implemented"})
    except Exception as e:  # report, keep the benchmark going
        out.put({"status": f"error: {type(e).__name__}: {e}"})


def run_one(level_path: Path, algo: str, repeats: int, timeout: float) -> dict:
    q: mp.Queue = mp.Queue()
    p = mp.Process(target=measure, args=(str(level_path), algo, repeats, q))
    p.start()
    p.join(timeout)
    if p.is_alive():
        p.terminate()
        p.join()
        return {"status": f"timeout>{timeout:g}s"}
    return q.get() if not q.empty() else {"status": "error: no result"}


def write_summary(rows: list[dict], path: Path, algos: list[str]) -> None:
    """Averages per level group and algorithm, as a Markdown table."""
    lines = [
        "# Benchmark summary",
        "",
        f"Machine: {platform.platform()}, Python {platform.python_version()}, "
        f"CPU: {platform.processor() or 'unknown'}",
        "",
        "Averages over the levels of each group (solved levels only).",
        "",
        "| Group | Algorithm | Solved | Avg length | Avg cost | Avg expanded | Avg time (ms) | Avg peak (KB) |",
        "| --- | --- | --- | --- | --- | --- | --- | --- |",
    ]
    groups = [g for g in GROUP_ORDER if any(r["group"] == g for r in rows)]
    groups += sorted({r["group"] for r in rows} - set(groups))
    for g in groups:
        for a in algos:
            rs = [r for r in rows if r["group"] == g and r["algo"] == a]
            ok = [r for r in rs if r["status"] == "ok"]
            if not ok:
                status = rs[0]["status"] if rs else "-"
                lines.append(f"| {g} | {a} | 0/{len(rs)} ({status}) | - | - | - | - | - |")
                continue
            avg = lambda k: statistics.mean(float(r[k]) for r in ok)  # noqa: E731
            lines.append(f"| {g} | {a} | {len(ok)}/{len(rs)} | {avg('length'):.1f} | {avg('cost'):.1f} | "
                         f"{avg('expanded'):.1f} | {avg('time_ms'):.2f} | {avg('peak_kb'):.1f} |")
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--levels", default=str(ROOT / "levels"))
    p.add_argument("--out", default=str(ROOT / "results" / "benchmark.csv"))
    p.add_argument("--algos", nargs="+", default=list(ALGORITHMS))
    p.add_argument("--repeats", type=int, default=5, help="timed runs per (level, algo); median kept")
    p.add_argument("--timeout", type=float, default=300.0, help="seconds per (level, algo)")
    args = p.parse_args()

    level_files = sorted(Path(args.levels).glob("level*.json"))
    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    rows: list[dict] = []
    t0 = time.perf_counter()
    for f in level_files:
        level = load_level(f)
        for algo in args.algos:
            r = run_one(f, algo, args.repeats, args.timeout)
            row = {"level": level.id, "name": level.name, "group": level.group, "algo": algo,
                   **{k: "" for k in FIELDS[4:]}, **r}
            rows.append(row)
            shown = (f"len={row['length']} cost={row['cost']} exp={row['expanded']} "
                     f"{row['time_ms']}ms {row['peak_kb']}KB") if row["status"] == "ok" else row["status"]
            print(f"level{level.id:02d} {algo:6s} {shown}", flush=True)

    with out.open("w", newline="", encoding="utf-8") as fh:
        w = csv.DictWriter(fh, fieldnames=FIELDS)
        w.writeheader()
        w.writerows(rows)
    write_summary(rows, out.with_name("summary.md"), args.algos)
    print(f"\nWrote {out} and {out.with_name('summary.md')} in {time.perf_counter() - t0:.1f}s")


if __name__ == "__main__":
    main()
