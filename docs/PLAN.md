# Kế hoạch và phân vai (cập nhật 2026-10-14)

Deadline: **22:00 ngày 2026-11-01**. Mục tiêu nội bộ: nộp trước **12:00 ngày 2026-11-01**.

## Vai trò

Trưởng nhóm đã nhận phần của mình. Bốn vai còn lại (A–D) nhóm tự gán tên vào bảng.

| Vai | Thành viên | Phụ trách code | Phần báo cáo |
| --- | --- | --- | --- |
| Trưởng nhóm | (trưởng nhóm) | `gui/` Godot 4 (3D, hoạt ảnh, UI, gọi TCP), `tests/` (unit test cho luật và solver) | Mô tả GUI, kiểm thử; dựng video |
| A — Core luật | | `bloxorz/core/rules.py`: bảng lăn, fragile, bridge, 3 switch, split/merge, cost | Mô hình hoá bài toán (state, action, transition, goal) |
| B — BFS, DFS/IDS | | `bloxorz/search/bfs.py`, `dfs.py` | Mô tả BFS, DFS/IDS, xử lý trạng thái lặp |
| C — UCS, A\* | | `bloxorz/search/ucs.py`, `astar.py`, `heuristics.py` | Hàm chi phí, heuristic, chứng minh admissible/consistent |
| D — Tích hợp & thí nghiệm | | `bloxorz/server.py`, `benchmark/`, `levels/` (20 màn) | Bộ test case, bảng + biểu đồ, nhận xét |

Cả nhóm: viết phần báo cáo của mình, ghi prompt AI vào `docs/AI_USAGE.md`, hiểu cả 4 thuật toán để vấn đáp.

## Lộ trình

| Giai đoạn | Ngày | Việc chính | Xong khi |
| --- | --- | --- | --- |
| 0. Khởi động | 14–16/10 | Clone repo, cài Python + Godot 4; A làm `roll()`; Trưởng nhóm dựng bàn tĩnh từ JSON | `pytest tests/test_roll.py` pass; Godot hiện level01 |
| 1. Lõi cơ bản | 17–21/10 | A: luật cơ bản + fragile + switch; B, C: 4 solver; D: server TCP + 10 màn; Trưởng nhóm: hoạt ảnh lăn, chơi tay qua TCP | `test_rules`, `test_golden`, `test_solvers` pass trên 3 màn mẫu; chơi tay được trên GUI |
| 2. Nâng cao | 22–26/10 | A: split/merge; C: heuristic cho split; D: đủ 20 màn + benchmark; Trưởng nhóm: hiệu ứng cầu/rơi/hai cube, nút Solve | 20 màn chơi được; Solve cho khối tự lăn tới đích |
| 3. Thí nghiệm & báo cáo | 27–29/10 | Chạy benchmark, làm bảng + biểu đồ, viết báo cáo | Bản nháp báo cáo đủ mục |
| 4. Video & nộp | 30/10–1/11 | Quay video, đăng YouTube public, đóng gói `MSSV1_MSSV2_..zip` | Nộp trước 12:00 1/11 |

## Rủi ro

| Rủi ro | Cách giảm |
| --- | --- |
| Split/merge phức tạp | A làm ngay đầu giai đoạn 2, có test riêng |
| TCP Godot ↔ Python lỗi | D làm lệnh `move` sớm trong giai đoạn 1 |
| Luật hiểu khác nhau | Chỉ `docs/GAME_RULES.md` là chuẩn; mọi đổi luật phải báo nhóm |
| Bị vấn đáp | Mỗi người tự chạy và giải thích được cả 4 solver |
