# Định dạng JSON — Project 1 Bloxorz (v1, chốt 2026-10-14)

Người dùng giao trợ lý thống nhất định dạng. Cả GUI và solver Python cùng đọc file màn; solver trả file kết quả.

## 1. Quy ước chung

- Tọa độ `[r, c]`: `r` là hàng (0 = trên cùng), `c` là cột (0 = trái cùng).
- Hướng: `"U"` (r-1), `"D"` (r+1), `"L"` (c-1), `"R"` (c+1). Action đổi cube khi đã tách: `"SWITCH"`.
- Tư thế: `"STAND"`; `"H"` chiếm `[r,c]` và `[r,c+1]`; `"V"` chiếm `[r,c]` và `[r+1,c]`. Ô neo luôn là ô trên/trái.

## 2. File màn chơi `levels/levelXX.json`

```json
{
  "id": 7,
  "name": "Fragile bridge",
  "group": "switch",
  "source": "Bloxorz Coolmath level 4 (chuyển thể)",
  "grid": [
    "###-----------",
    "####---FFF####",
    "##S##oFFFFF#G#",
    "-####BB###X###",
    "------####--##"
  ],
  "start": { "pos": [2, 2], "orient": "STAND" },
  "bridges": [
    { "id": "b1", "cells": [[3, 5], [3, 6]], "open": false }
  ],
  "switches": [
    { "id": "s1", "pos": [2, 5], "type": "soft",  "mode": "toggle", "bridges": ["b1"] },
    { "id": "s2", "pos": [3, 10], "type": "heavy", "mode": "open",   "bridges": ["b1"] }
  ]
}
```

Ký tự trong `grid` (mọi hàng cùng độ dài):

| Ký tự | Ý nghĩa |
| --- | --- |
| `-` | void |
| `#` | floor |
| `F` | fragile |
| `G` | goal (đúng 1 ô) |
| `S` | ô xuất phát (là floor; vị trí thật lấy từ `start`) |
| `o` | soft switch |
| `X` | heavy switch |
| `P` | split switch |
| `B` | ô cầu; trạng thái ban đầu lấy từ `bridges[].open` |

Trường của `switches[]`:

- `type`: `"soft"`, `"heavy"`, `"split"`.
- `mode`: `"toggle"` đảo trạng thái; `"open"`/`"close"` là kiểu permanent, đặt cố định.
- `bridges`: danh sách id cầu bị tác động. Với split switch có thể để rỗng.
- Riêng split switch: `"split_to": [[r1, c1], [r2, c2]]`. Cube 1 được điều khiển trước.

`group` thuộc một trong năm giá trị: `basic`, `fragile`, `switch`, `split`, `hard` (màn lớn) — 5 nhóm × 3 màn = 15 màn.

## 3. Trạng thái (GUI ↔ Python, và để debug)

```json
{ "mode": "whole", "pos": [2, 2], "orient": "STAND", "open_bridges": ["b1"] }
{ "mode": "split", "cubes": [[1, 3], [4, 8]], "active": 0, "open_bridges": [] }
```

## 4. Kết quả solver `results/levelXX_<algo>.json`

```json
{
  "level": 7,
  "algo": "astar",
  "found": true,
  "actions": ["R", "R", "D", "SWITCH", "L"],
  "metrics": { "time_ms": 12.4, "peak_kb": 840, "expanded": 1204, "length": 5, "cost": 6 }
}
```

- `algo`: `"bfs"`, `"dfs"` (hoặc `"ids"`), `"ucs"`, `"astar"`.
- `length` = số action, tính cả `SWITCH`. `cost` theo hàm chi phí của nhóm.
- Không có lời giải: `"found": false`, `"actions": []`.

Gọi solver từ GUI (đề xuất):

```text
python -m bloxorz solve levels/level07.json --algo astar --out results/level07_astar.json
```

## 5. Luật áp dụng

Xem [GAME_RULES.md](GAME_RULES.md).
