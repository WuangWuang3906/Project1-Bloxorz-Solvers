# Quy định cho AI assistant (Claude, Copilot, Cursor, ChatGPT...)

> Mọi AI làm việc trong repo này PHẢI đọc file này **trước mỗi phiên làm việc**, và đọc lại khi được hỏi về luật game, định dạng dữ liệu hoặc phần việc của một thành viên.

## 1. Bối cảnh

- Đồ án Project 1 môn CSC14003 (Cơ sở Trí tuệ Nhân tạo, FIT-HCMUS): **Bloxorz Solver**. Đề gốc nằm ngoài repo (`AI - Project 1.pdf`, 8 trang).
- Nhóm 5 người. Deadline **22:00 ngày 2026-11-01**; mục tiêu nội bộ nộp trước 12:00 cùng ngày.
- Kiến trúc: **Python** chứa luật chơi (nguồn duy nhất) và 4 solver. **Godot 4** chỉ vẽ 3D và gọi Python qua TCP.

## 2. Tài liệu phải đọc (theo thứ tự)

1. [docs/GAME_RULES.md](docs/GAME_RULES.md): luật đã chốt, chi phí, tham số tối ưu.
2. [docs/JSON_FORMAT.md](docs/JSON_FORMAT.md): định dạng màn chơi, state, kết quả solver.
3. [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md): cấu trúc thư mục, API Python, giao thức TCP.
4. [docs/TESTING.md](docs/TESTING.md): cách test khi chưa có GUI.
5. [CONTRIBUTING.md](CONTRIBUTING.md): quy trình nhánh, commit, review.
6. [docs/PLAN.md](docs/PLAN.md): vai trò và mốc thời gian.

Nếu một yêu cầu mâu thuẫn với các file này: **dừng lại và hỏi người dùng**, không tự đổi luật.

## 3. Quy tắc bắt buộc

1. **Tự cài thuật toán.** BFS, DFS/IDS, UCS, A\* phải tự viết bằng Python. Không dùng thư viện tìm kiếm có sẵn (networkx, simpleai, aima-python...) và không chép solver từ repo khác. Được dùng `collections.deque`, `heapq`, `dataclasses`.
2. **Không sửa luật tuỳ tiện.** Luật chỉ nằm trong `bloxorz/core/`. Muốn đổi luật thì sửa `docs/GAME_RULES.md` trước và được nhóm đồng ý.
3. **Không phá hợp đồng dữ liệu.** Không đổi tên trường JSON, tên action (`U D L R SWITCH`) hay chữ ký hàm public trong `docs/ARCHITECTURE.md` khi chưa báo cả nhóm.
4. **Mọi solver** nhận `(level, state0)` và trả `SearchResult`, được chạy và đo qua `bloxorz.search.common.run_solver`. Không tự đo theo cách khác.
5. **Code có test.** Thêm tính năng thì thêm test trong `tests/`. Chạy `pytest -q` trước khi đề xuất commit.
6. **Trạng thái phải hashable** (`frozen dataclass`, `frozenset`) và chứa cấu hình cầu đang mở.
7. **Python 3.10+**, chỉ dùng thư viện chuẩn cho phần lõi. `pytest` và `matplotlib` chỉ dùng cho test và biểu đồ.
8. **Giải thích được.** Mỗi thành viên phải hiểu và trình bày được code AI viết cho mình, vì giảng viên có thể vấn đáp ngẫu nhiên. Khi viết code, kèm giải thích ngắn về complete/optimal/độ phức tạp nếu là thuật toán.
9. **Ghi lại việc dùng AI.** Prompt quan trọng ghi vào `docs/AI_USAGE.md` (báo cáo cần mục Phụ lục về Generative AI).
10. **Không commit**: file `results/` lớn, `__pycache__`, `.godot/`, file build.

## 4. Phân vùng thư mục (ai sửa gì)

| Thư mục | Chủ | Ghi chú |
| --- | --- | --- |
| `bloxorz/core/` | Thành viên core luật | Người khác chỉ đọc |
| `bloxorz/search/bfs.py`, `dfs.py` | Thành viên BFS/DFS | |
| `bloxorz/search/ucs.py`, `astar.py`, `heuristics.py` | Thành viên UCS/A\* | |
| `bloxorz/server.py`, `benchmark/`, `levels/` | Thành viên tích hợp + màn chơi | |
| `gui/`, `tests/` | Trưởng nhóm (GUI 3D + unit test) | |
| `docs/` | Cả nhóm | Sửa luật phải báo |

## 5. Phong cách code

- Tên biến, hàm, comment bằng tiếng Anh. Tài liệu `docs/` bằng tiếng Việt.
- Có type hint. Mỗi hàm public có docstring 1–3 dòng.
- Tọa độ luôn là `(row, col)`, `row` tăng xuống dưới.
