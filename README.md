# Project 1 — Bloxorz Solvers (CSC14003, FIT-HCMUS)

Game Bloxorz 3D (Godot 4) và 4 thuật toán tìm kiếm tự cài bằng Python: **BFS, DFS/IDS, UCS, A\***.

## Cấu trúc

```text
bloxorz/        Python: luật game (core/) + solver (search/) + TCP server
gui/            Godot 4: giao diện 3D
levels/         màn chơi JSON
tests/          pytest
benchmark/      chạy thí nghiệm cho báo cáo
docs/           luật, định dạng JSON, kiến trúc, cách test, kế hoạch
```

## Bắt đầu

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
pytest -q
python -m bloxorz show levels/level01.json
```

Đọc tiếp: [AGENTS.md](AGENTS.md) (quy định chung, cả cho AI) → [docs/TESTING.md](docs/TESTING.md) → [CONTRIBUTING.md](CONTRIBUTING.md).

## Chạy

| Việc | Lệnh |
| --- | --- |
| Xem màn chơi | `python -m bloxorz show levels/level01.json` |
| Chơi trong terminal | `python -m bloxorz play levels/level01.json` |
| Giải | `python -m bloxorz solve levels/level01.json --algo astar` |
| Kiểm chứng lời giải | `python -m bloxorz verify levels/level01.json results/x.json` |
| Server cho GUI | `python -m bloxorz.server --port 5555` |
| Benchmark | `python benchmark/run_benchmark.py` |
| GUI | Mở `gui/project.godot` bằng Godot 4 |

## Tham khảo

- Bloxorz — Coolmath Games: https://www.coolmathgames.com/0-bloxorz
- Russell & Norvig, *Artificial Intelligence: A Modern Approach*, 4th ed., chương 3.
