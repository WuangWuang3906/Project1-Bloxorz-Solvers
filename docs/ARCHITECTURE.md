# Kiến trúc và API

## 1. Cây thư mục

```text
bloxorz/                  # Python package (luật + solver)
  __main__.py             # python -m bloxorz ...
  cli.py                  # show / play / solve / verify
  core/
    level.py              # Level, Bridge, Switch, load_level()        [đã có]
    state.py              # State                                        [đã có]
    rules.py              # roll(), step(), successors(), is_goal()...   [TODO core]
    render.py             # render_text(): vẽ bàn cờ bằng chữ           [đã có]
  search/
    common.py             # SearchResult, measure(), reconstruct()      [đã có]
    bfs.py dfs.py         # [TODO BFS/DFS]
    ucs.py astar.py heuristics.py   # [TODO UCS/A*]
  server.py               # TCP server cho Godot                        [TODO tích hợp]
benchmark/run_benchmark.py  # chạy mọi màn × mọi thuật toán, xuất CSV   [TODO tích hợp]
levels/                   # levelXX.json
results/sample/           # kết quả giả cho GUI test
tests/                    # pytest
gui/                      # project Godot 4
docs/
```

## 2. API Python (hợp đồng — không đổi khi chưa báo nhóm)

### `bloxorz.core.state.State` (frozen, hashable)

| Trường | Khối nguyên | Đã tách |
| --- | --- | --- |
| `pos` | ô neo `(r, c)` | ô cube 0 |
| `orient` | `"STAND"`, `"H"`, `"V"` | `"SPLIT"` |
| `cubes` | `None` | `((r0,c0), (r1,c1))` |
| `active` | `0` | `0` hoặc `1` |
| `open_bridges` | `frozenset[str]` | `frozenset[str]` |

### `bloxorz.core.rules`

```python
roll(pos, orient, direction) -> tuple[pos, orient]     # chỉ bảng lăn, không xét bàn cờ
occupied_cells(state) -> list[tuple[int, int]]
initial_state(level) -> State
step(level, state, action) -> StepResult               # StepResult(state | None, cost, events)
successors(level, state) -> Iterator[tuple[str, State, float]]   # chỉ nước hợp lệ
is_goal(level, state) -> bool
apply_actions(level, actions) -> list[State]           # ném IllegalMove nếu sai
verify(level, actions) -> bool                         # hợp lệ và kết thúc ở goal
```

`events` là danh sách chuỗi để GUI làm hoạt ảnh: `"fall"`, `"win"`, `"bridge:b1:open"`, `"bridge:b1:close"`, `"split"`, `"merge"`, `"fragile_break"`.

### `bloxorz.search`

```python
def bfs(level, start: State) -> SearchResult: ...
# tương tự dfs (hoặc ids), ucs, astar(level, start, heuristic=...)
```

`SearchResult(found, actions, cost, expanded, time_ms, peak_kb)`. Chạy qua `run_solver()` để đo thống nhất (thời gian đo ở lần chạy không bật `tracemalloc`, bộ nhớ đo ở lần chạy thứ hai). Đăng ký trong `bloxorz/search/__init__.py` ở dict `ALGORITHMS`.

**Quy ước đếm `expanded`:** tăng 1 mỗi khi một node được **lấy ra khỏi frontier và sinh con** (không tính node bị bỏ vì đã thăm).

## 3. Giao thức TCP (Godot ↔ Python)

- `python -m bloxorz.server --port 5555`, chỉ nghe `127.0.0.1`.
- Mỗi message là **một dòng JSON** kết thúc bằng `\n`.

| Godot gửi | Python trả |
| --- | --- |
| `{"cmd":"load","level":{...JSON màn...}}` (GUI dùng cách này) hoặc `{"cmd":"load","path":"levels/level01.json"}` | `{"ok":true,"level":{...},"state":{...}}` |
| `{"cmd":"move","action":"R"}` (cả `SWITCH`) | `{"ok":true,"state":{...},"events":["bridge:b1:open"]}` hoặc `{"ok":true,"state":null,"events":["fall"]}` |
| `{"cmd":"apply","actions":["R","D",...]}` (nhiều nước một lúc, dùng khi bỏ qua phát lại) | `{"ok":true,"state":{...},"events":[...]}` của nước cuối; dừng ở nước rơi đầu tiên (`"state":null`) |
| `{"cmd":"restart"}` | `{"ok":true,"state":{...}}` |
| `{"cmd":"solve","algo":"astar"}` | `{"ok":true,"result":{...}}` (dạng file kết quả trong JSON_FORMAT). Chặn tới khi giải xong; dùng cho CLI/test |
| `{"cmd":"solve_start","algo":"bfs"}` | `{"ok":true}` ngay. Solver chạy ở tiến trình phụ (`bloxorz/solve_job.py`), server vẫn trả lời các lệnh khác |
| `{"cmd":"solve_poll"}` | `{"ok":true,"phase":"solving"/"measuring"/"done"/"error"/"idle","result":{...}/null,"error":...}`. `measuring` = đã có lời giải và thời gian, `peak_kb` còn `null` (đang đo bộ nhớ bằng tracemalloc). Thêm `"progress"` (số nút đã mở rộng tới giờ) và `"total"` (số trạng thái đi tới được của màn, từ `bloxorz/data/state_counts.json`, `null` nếu chưa đếm) |
| `{"cmd":"solve_cancel"}` | `{"ok":true}`; huỷ solver đang chạy. `load`/`restart` cũng tự huỷ |
| lỗi | `{"ok":false,"error":"..."}` |

Khi nhận `result`, Godot gửi lần lượt từng `move` để vừa có hoạt ảnh vừa kiểm chứng.

GUI đang dùng giao thức này như sau (đã cài trong `gui/scripts/net_client.gd`):

- Server chạy ở **thư mục gốc repo**; `path` trong `load` là đường dẫn tương đối như `levels/level04.json`.
- Mỗi lần mở màn, chơi lại, hoặc **sau khi khối rơi**, GUI gửi lại `load` (không dùng `restart`).
- `move` hợp lệ: trả `state` mới. Khối rơi: trả `"state": null` và có `"fall"` trong `events`.
- GUI không gửi `move` đè lên cube kia và không gửi `SWITCH` khi chưa tách.
- `solve` giải từ **trạng thái đầu** của màn đang load; trả `result` đúng định dạng file kết quả.
- GUI dùng `solve_start` + `solve_poll` (mỗi 0,15 s), bắt đầu phát lại khi `phase` = `measuring`, rồi điền Peak mem khi `done`. Mỗi lần Restart/đổi màn/bấm thuật toán khác, GUI tăng một số "epoch": việc của epoch cũ (chờ giải, phát lại, hoạt ảnh, request chưa gửi) bị bỏ. `net_client.gd` chỉ cho **một request** chạy một lúc để không lẫn câu trả lời.
