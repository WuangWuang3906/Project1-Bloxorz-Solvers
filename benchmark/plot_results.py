"""Draw report charts from results/benchmark.csv (run run_benchmark.py first).

Run from the repo root:  python benchmark/plot_results.py
Writes one PNG per metric to results/figures/: grouped bars, one group per
level group, one bar per algorithm (average over the solved levels).
The matching numbers are in results/summary.md (use it as the table view).
"""
from __future__ import annotations

import argparse
import csv
import statistics
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402
from matplotlib.patches import Patch  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]

# Fixed categorical order (validated for colour-vision deficiency): colour
# follows the algorithm, never its rank, so a missing algorithm keeps its slot.
ALGOS = ["bfs", "dfs", "ucs", "astar"]
LABELS = {"bfs": "BFS", "dfs": "DFS", "ucs": "UCS", "astar": "A*"}
COLORS = {"bfs": "#2a78d6", "dfs": "#eb6834", "ucs": "#1baf7a", "astar": "#eda100"}
GROUPS = ["basic", "fragile", "switch", "split"]
GROUP_LABELS = {"basic": "Cơ bản", "fragile": "Ô dễ vỡ", "switch": "Công tắc & cầu", "split": "Tách khối"}

SURFACE, INK, INK_2, GRID = "#fcfcfb", "#0b0b0b", "#52514e", "#e4e3df"

METRICS = [
    ("expanded", "Số nút mở rộng trung bình", "nút", "expanded.png"),
    ("time_ms", "Thời gian tìm kiếm trung bình", "ms", "time.png"),
    ("peak_kb", "Bộ nhớ đỉnh trung bình", "KB", "memory.png"),
    ("length", "Độ dài lời giải trung bình", "số nước", "length.png"),
    ("cost", "Tổng chi phí lời giải trung bình", "chi phí", "cost.png"),
]


def load(path: Path) -> list[dict]:
    with path.open(encoding="utf-8") as fh:
        return [r for r in csv.DictReader(fh) if r["status"] == "ok"]


def averages(rows: list[dict], key: str) -> dict[tuple[str, str], float]:
    out = {}
    for g in GROUPS:
        for a in ALGOS:
            vals = [float(r[key]) for r in rows if r["group"] == g and r["algo"] == a]
            if vals:
                out[(g, a)] = statistics.mean(vals)
    return out


def bar_chart(avg: dict, title: str, unit: str, out: Path) -> None:
    fig, ax = plt.subplots(figsize=(8, 4.2), dpi=200)
    fig.patch.set_facecolor(SURFACE)
    ax.set_facecolor(SURFACE)
    n = len(ALGOS)
    width = 0.8 / n
    for i, a in enumerate(ALGOS):
        xs, ys = [], []
        for gi, g in enumerate(GROUPS):
            if (g, a) in avg:
                xs.append(gi - 0.4 + width * (i + 0.5))
                ys.append(avg[(g, a)])
        # surface-coloured edge = the 2px gap between adjacent bars
        ax.bar(xs, ys, width=width, color=COLORS[a], edgecolor=SURFACE, linewidth=1.5, zorder=3)
    ax.set_xticks(range(len(GROUPS)), [GROUP_LABELS[g] for g in GROUPS], color=INK)
    ax.set_ylabel(unit, color=INK_2)
    ax.set_title(title, loc="left", color=INK, fontsize=12, fontweight="bold", pad=28)
    ax.yaxis.grid(True, color=GRID, linewidth=0.8, zorder=0)
    ax.tick_params(colors=INK_2, length=0)
    for side in ("top", "right", "left"):
        ax.spines[side].set_visible(False)
    ax.spines["bottom"].set_color(GRID)
    present = {a for (_, a) in avg}
    handles = [Patch(facecolor=COLORS[a], label=LABELS[a] if a in present else f"{LABELS[a]} (chưa có)")
               for a in ALGOS]
    ax.legend(handles=handles, ncol=n, frameon=False, loc="lower left", bbox_to_anchor=(0, 1.0), fontsize=9,
              labelcolor=INK_2, handlelength=1.2, borderaxespad=0.2)
    fig.tight_layout()
    fig.savefig(out, facecolor=SURFACE)
    plt.close(fig)


def main() -> None:
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument("--csv", default=str(ROOT / "results" / "benchmark.csv"))
    p.add_argument("--out", default=str(ROOT / "results" / "figures"))
    args = p.parse_args()
    rows = load(Path(args.csv))
    out_dir = Path(args.out)
    out_dir.mkdir(parents=True, exist_ok=True)
    for key, title, unit, fname in METRICS:
        bar_chart(averages(rows, key), title, unit, out_dir / fname)
        print("wrote", out_dir / fname)


if __name__ == "__main__":
    main()
