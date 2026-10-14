# Nhận việc — đọc trong 10 phút

> Trưởng nhóm đã xong GUI 3D và bộ unit test. Việc còn lại là **phần Python**: luật chơi, 4 thuật toán, server và thí nghiệm. File này nói mỗi người làm gì, làm theo thứ tự nào, và thế nào là xong.

## 1. Bức tranh chung

```text
 levels/*.json ──► bloxorz/core (luật)  ──► bloxorz/search (BFS, DFS, UCS, A*)
                        │                         │
                        └──── bloxorz/server.py ◄─┘ ──TCP──► GUI Godot (đã xong)
                                     │
                         benchmark/ (số liệu cho báo cáo)
```

- **Luật chơi chỉ viết một lần, bằng Python** (`bloxorz/core/rules.py`). GUI, solver và benchmark đều gọi luật này.
- Solver không biết gì về GUI. Bạn test hoàn toàn bằng terminal (`docs/TESTING.md`).
- **Bài toán tìm kiếm**:
  - *State* = vị trí khối + tư thế (`STAND`/`H`/`V`/`SPLIT`) + **tập cầu đang mở** (+ vị trí 2 cube và cube đang điều khiển khi tách). Cùng vị trí khối nhưng khác cầu là **hai state khác nhau**.
  - *Action* = `U D L R`, thêm `SWITCH` khi đã tách.
  - *Transition* = `rules.step()`; *successors* = `rules.successors()` (chỉ nước hợp lệ).
  - *Goal* = khối nguyên đứng trên `G`.
  - *Cost* = 1 mỗi nước, 2 nếu kết thúc nằm trên ô dễ vỡ (`docs/GAME_RULES.md` mục 6).

## 2. Bắt đầu (mọi người, ~15 phút)

```bash
git clone https://github.com/WuangWuang3906/Project1-Bloxorz-Solvers.git
cd Project1-Bloxorz-Solvers
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
pytest -q                                   # lúc đầu: 4 pass, phần còn lại fail
python -m bloxorz show levels/level03.json
git checkout -b feat/<vai>-<việc>           # ví dụ feat/core-roll
```

Rồi đọc theo thứ tự: `AGENTS.md` → `docs/GAME_RULES.md` → `docs/ARCHITECTURE.md` → mục của mình bên dưới. Nếu dùng AI, cho nó đọc `AGENTS.md` trước (Claude/Copilot/Cursor tự đọc).

**Test fail không phải lỗi của bạn** — đó là danh sách việc. Mỗi người làm cho các test thuộc phần mình chuyển sang pass.

## 3. Việc của từng vai

### A — Luật chơi (`bloxorz/core/rules.py`) · làm TRƯỚC, mọi người phụ thuộc

| Bước | Việc | Test phải pass | Hạn |
| --- | --- | --- | --- |
| A1 | `roll()` — bảng lăn 12 ô | `tests/test_roll.py` | **16/10** |
| A2 | `occupied_cells`, `initial_state`, `step`, `successors`, `is_goal` cho floor/void/goal/fragile | nhóm test "basic board" và "fragile" trong `tests/test_rules.py` | **17/10** |
| A3 | Cầu + 3 loại switch (`toggle`/`open`/`close`), cost | nhóm "bridges and switches" trong `test_rules.py`, `test_golden.py` level01–03 | 19/10 |
| A4 | Tách/nhập khối, `SWITCH` | `tests/test_split.py`, `test_golden.py` level04 | 23/10 |

Cần hiểu để giải thích khi vấn đáp: vì sao state phải **hashable** (dùng làm khoá trong `visited`), vì sao cấu hình cầu nằm trong state, thứ tự xử lý một nước (`GAME_RULES.md` mục 3).

### B — BFS và DFS/IDS (`bloxorz/search/bfs.py`, `dfs.py`)

| Bước | Việc | Test phải pass | Hạn |
| --- | --- | --- | --- |
| B1 | BFS: `deque`, `visited`, `parent` → `reconstruct()` | `test_solvers.py` (bfs) | 21/10 |
| B2 | DFS bằng **stack tường minh** (không đệ quy) + `visited`; hoặc IDS (ghi rõ trong báo cáo) | `test_solvers.py` (dfs) | 21/10 |
| B3 | Viết phần báo cáo: mô tả, complete/optimal/time/space **kèm điều kiện** | — | 28/10 |

Có thể viết ngay hôm nay dựa trên chữ ký `successors()` / `is_goal()` trong `ARCHITECTURE.md`; test sẽ chạy được khi A xong A2. Đếm `expanded` đúng quy ước trong `ARCHITECTURE.md`.

### C — UCS, A\* và heuristic (`ucs.py`, `astar.py`, `heuristics.py`)

| Bước | Việc | Test phải pass | Hạn |
| --- | --- | --- | --- |
| C1 | UCS bằng `heapq` (g, counter, state); bỏ qua state đã chốt với g nhỏ hơn | `test_solvers.py` (ucs) | 21/10 |
| C2 | A\* + heuristic cho khối nguyên (gợi ý: Manhattan/2, cộng thêm khi chưa đứng) | `test_astar_matches_ucs_cost` | 21/10 |
| C3 | Heuristic khi đã tách (2 cube, teleport) vẫn **admissible** | cost A\* = UCS trên level04 | 25/10 |
| C4 | Báo cáo: giải thích cost function, chứng minh admissible/consistent **theo cost đã chọn** | — | 28/10 |

Cần hiểu: vì sao UCS với cost đều = 1 trùng BFS; vì sao heuristic phải ≤ cost thật nhỏ nhất (mọi action cost ≥ 1).

### D — Server, màn chơi, thí nghiệm (`server.py`, `levels/`, `benchmark/`)

| Bước | Việc | Xong khi | Hạn |
| --- | --- | --- | --- |
| D1 | `server.py` theo giao thức `ARCHITECTURE.md` mục 3 | GUI hiện `● Python server`, chơi tay + Solve chạy | 19/10 (sau A2) |
| D2 | 20 màn JSON: 5 cơ bản, 5 fragile, 5 switch/bridge, 5 split/kết hợp; ghi `source` | mỗi màn có 1 lời giải thêm vào `test_golden.py` | 24/10 |
| D3 | `benchmark/run_benchmark.py`: 20 màn × 4 thuật toán → CSV | chạy hết không treo | 26/10 |
| D4 | Bảng + biểu đồ (matplotlib) cho báo cáo | — | 28/10 |

Server chạy ở thư mục gốc repo, cổng 5555. Thử GUI: `python tools/get_godot.py` rồi `tools\godot\Godot_v4.7.2-stable_win64.exe --path gui`.

## 4. Thứ tự phụ thuộc

```text
16/10  A1 roll ─┐
17/10  A2 luật cơ bản ──► B1, B2, C1, C2 chạy test được ──► D1 server
19/10  A3 cầu + switch ──► test_golden level01–03
23/10  A4 split ──► C3 heuristic split, D2 màn split
26/10  D3 benchmark ──► 27–29/10 báo cáo ──► 30/10–1/11 video + nộp
```

## 5. Quy tắc nhỏ nhưng quan trọng

- Mỗi việc một nhánh, mở **Pull Request**, 1 người khác duyệt mới merge (`CONTRIBUTING.md`).
- Chỉ sửa file thuộc vai mình. Thấy luật sai → báo nhóm, sửa `docs/GAME_RULES.md` trước.
- Không dùng thư viện tìm kiếm có sẵn, không chép solver repo khác.
- Ghi prompt AI quan trọng vào `docs/AI_USAGE.md`.
- **Hiểu code mình nộp**: giảng viên có thể vấn đáp ngẫu nhiên bất kỳ ai về bất kỳ thuật toán nào.
- Kẹt quá nửa ngày → nhắn nhóm ngay, đừng im.
