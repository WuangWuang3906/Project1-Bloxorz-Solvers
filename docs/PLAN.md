# Kế hoạch và phân vai (cập nhật 2026-10-14)

Deadline: **22:00 ngày 2026-11-01**. Mục tiêu nội bộ: nộp trước **12:00 ngày 2026-11-01**.

## Vai trò

| Người | Phụ trách | Phần báo cáo |
| --- | --- | --- |
| Trưởng nhóm | GUI Godot, unit test, **luật chơi** (`bloxorz/core/`), server, 15 màn, benchmark, video, ghép báo cáo | GUI, mô hình hoá bài toán, thí nghiệm |
| Thành viên 1 | BFS (`bloxorz/search/bfs.py`) | BFS |
| Thành viên 2 | DFS hoặc IDS (`bloxorz/search/dfs.py`) | DFS/IDS |
| Thành viên 3 | UCS (`bloxorz/search/ucs.py`) | UCS + hàm chi phí |
| Thành viên 4 | A\* (`bloxorz/search/astar.py`, `heuristics.py`) | A\* + heuristic, chứng minh admissible |

Nhóm tự điền tên. Cả nhóm hiểu cả 4 thuật toán để vấn đáp; ghi prompt AI vào `docs/AI_USAGE.md`.

## Lộ trình

| Giai đoạn | Việc chính | Xong khi |
| --- | --- | --- |
| 0. Khởi động | Clone repo, cài Python + Godot 4; A làm `roll()`; Trưởng nhóm dựng bàn tĩnh từ JSON | `pytest tests/test_roll.py` pass; Godot hiện level01 |
| 1. Lõi cơ bản | A: luật cơ bản + fragile + switch; B, C: 4 solver; D: server TCP + 10 màn; Trưởng nhóm: hoạt ảnh lăn, chơi tay qua TCP | `test_rules`, `test_golden`, `test_solvers` pass trên 3 màn mẫu; chơi tay được trên GUI |
| 2. Nâng cao | A: split/merge; C: heuristic cho split; D: đủ 15 màn + benchmark; Trưởng nhóm: hiệu ứng cầu/rơi/hai cube, nút Solve | 20 màn chơi được; Solve cho khối tự lăn tới đích |
| 3. Thí nghiệm & báo cáo | Chạy benchmark, làm bảng + biểu đồ, viết báo cáo | Bản nháp báo cáo đủ mục |
| 4. Video & nộp | Quay video, đăng YouTube public, đóng gói `MSSV1_MSSV2_..zip` | Nộp trước 12:00 1/11 |

## Rủi ro

| Rủi ro | Cách giảm |
| --- | --- |
| Split/merge phức tạp | A làm ngay đầu giai đoạn 2, có test riêng |
| TCP Godot ↔ Python lỗi | D làm lệnh `move` sớm trong giai đoạn 1 |
| Luật hiểu khác nhau | Chỉ `docs/GAME_RULES.md` là chuẩn; mọi đổi luật phải báo nhóm |
| Bị vấn đáp | Mỗi người tự chạy và giải thích được cả 4 solver |
