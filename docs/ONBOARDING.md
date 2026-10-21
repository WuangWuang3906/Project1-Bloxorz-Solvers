# Nhận việc — đọc trong 10 phút

> Trưởng nhóm đã xong GUI 3D, unit test và luật chơi. Mỗi bạn còn lại viết **một thuật toán**: BFS, DFS, UCS hoặc A\*. File này nói mỗi người làm gì và thế nào là xong.

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
pytest -q                                   # phần luật đã pass; test thuật toán fail cho tới khi bạn viết xong
python -m bloxorz show levels/level03.json
git checkout -b feat/<thuật-toán>           # ví dụ feat/bfs
```

Rồi đọc theo thứ tự: `AGENTS.md` → `docs/GAME_RULES.md` → `docs/ARCHITECTURE.md` → mục của mình bên dưới. Nếu dùng AI, cho nó đọc `AGENTS.md` trước (Claude/Copilot/Cursor tự đọc).

**Test fail không phải lỗi của bạn** — đó là danh sách việc. Mỗi người làm cho các test thuộc phần mình chuyển sang pass.

## 3. Việc của từng người

**Trưởng nhóm** đã làm xong: GUI 3D, unit test và **luật chơi** (`bloxorz/core/rules.py`, 66 test luật đều pass). Trưởng nhóm làm tiếp server, màn chơi và đo đạc. **4 bạn còn lại mỗi người một thuật toán**, mỗi người một file:

| Người | Thuật toán | File | Biết là xong khi |
| --- | --- | --- | --- |
| 1 | **BFS** — thử hết đường 1 bước, rồi 2 bước… → luôn ra đường ít nước nhất | `bloxorz/search/bfs.py` | `pytest tests/test_solvers.py -k bfs` PASSED |
| 2 | **DFS** (hoặc IDS) — đi một hướng tới cùng, bí thì quay lại | `bloxorz/search/dfs.py` | `pytest tests/test_solvers.py -k dfs` PASSED |
| 3 | **UCS** — luôn mở rộng đường có tổng giá thấp nhất | `bloxorz/search/ucs.py` | `pytest tests/test_solvers.py -k "ucs and not astar"` PASSED |
| 4 | **A\*** — như UCS nhưng có heuristic ước lượng còn bao xa | `bloxorz/search/astar.py`, `heuristics.py` | `-k astar` PASSED và `test_astar_matches_ucs_cost` PASSED |

Mỗi người cũng viết **phần báo cáo của thuật toán mình**: ý tưởng, có chắc tìm ra lời giải không (complete), có tối ưu không (optimal), tốn thời gian/bộ nhớ thế nào — **kèm điều kiện** để kết luận đúng.

Luật chơi đã có sẵn, nên ai cũng chạy thử được ngay:

```bash
python -m bloxorz solve levels/level01.json --algo bfs --replay
```

### Gợi ý cho từng thuật toán

- **BFS**: `collections.deque`; đánh dấu đã thăm khi **sinh ra** state; lưu `parent[state] = (state_trước, action)` rồi dùng `common.reconstruct()`.
- **DFS**: dùng **stack tường minh** (list + `pop()`), không dùng đệ quy (Python giới hạn ~1000 tầng). Phải có `visited` để không đi vòng tròn (đề tr. 5). Nếu chọn IDS thì ghi rõ trong báo cáo.
- **UCS**: `heapq` với `(g, counter, state)`; khi lấy ra một state đã chốt với g nhỏ hơn thì bỏ qua. Giá mỗi bước lấy từ `successors()` (lăn = 1, kết thúc nằm trên ô dễ vỡ = 2, `SWITCH` = 1).
- **A\***: như UCS nhưng ưu tiên `g + h`. Heuristic **không được ước lượng quá** giá thật — vì mọi bước tốn ≥ 1, khoảng cách Manhattan tới đích chia 2 là an toàn. Cần xử lý cả lúc khối đã tách (màn 4). Báo cáo phải chứng minh admissible (và consistent nếu được).

Đếm `expanded` theo quy ước trong `ARCHITECTURE.md`: +1 mỗi khi lấy một node ra khỏi frontier và sinh con.

### Trưởng nhóm làm tiếp

| Việc | Biết là xong khi |
| --- | --- |
| `bloxorz/server.py` (cầu nối GUI ↔ Python) | GUI hiện `● Python server`, bấm Solve chạy |
| Đủ 20 màn (5 cơ bản, 5 ô dễ vỡ, 5 công tắc/cầu, 5 tách khối) | mỗi màn có 1 lời giải trong `test_golden.py` |
| `benchmark/run_benchmark.py` + bảng, biểu đồ | chạy hết 20 màn × 4 thuật toán |
| Xuất `.exe`, video, ghép báo cáo | nộp trước 12:00 ngày 1/11 |

## 4. Thứ tự làm

```text
Luật chơi (xong) ──► 4 bạn viết BFS / DFS / UCS / A* song song, độc lập nhau
                 ──► trưởng nhóm: server, 20 màn, benchmark
4 thuật toán xong ──► chạy benchmark ──► cả nhóm viết báo cáo ──► video + nộp
```

## 5. Quy tắc nhỏ nhưng quan trọng

- Mỗi việc một nhánh, mở **Pull Request**, 1 người khác duyệt mới merge (`CONTRIBUTING.md`).
- Chỉ sửa file thuộc vai mình. Thấy luật sai → báo nhóm, sửa `docs/GAME_RULES.md` trước.
- Không dùng thư viện tìm kiếm có sẵn, không chép solver repo khác.
- Ghi prompt AI quan trọng vào `docs/AI_USAGE.md`.
- **Hiểu code mình nộp**: giảng viên có thể vấn đáp ngẫu nhiên bất kỳ ai về bất kỳ thuật toán nào.
- Kẹt quá nửa ngày → nhắn nhóm ngay, đừng im.
