# Trạng thái dự án (cập nhật 2026-10-21)

> File này là "bộ nhớ" của nhóm và của AI. **Đọc đầu tiên khi tiếp tục làm việc**, và cập nhật mỗi khi xong một mốc.

## 1. Đã xong

| Hạng mục | Kết quả | Ai | Nơi |
| --- | --- | --- | --- |
| Đọc đề + FAQ lớp | GUI phải 3D; GUI ngôn ngữ gì cũng được, thuật toán bằng Python; Solve phải cho khối tự lăn tới đích; ≥ 10 test case | Trưởng nhóm | đề `AI - Project 1.pdf` (ngoài repo) |
| Chốt luật, cost, JSON | Luật mục mơ hồ đã tự chốt theo game gốc | Trưởng nhóm + AI | `docs/GAME_RULES.md`, `docs/JSON_FORMAT.md` |
| Kiến trúc | Python = luật + solver (nguồn duy nhất); Godot chỉ vẽ; TCP 127.0.0.1:5555 | Trưởng nhóm + AI | `docs/ARCHITECTURE.md` |
| **Luật chơi** | `bloxorz/core/rules.py` hoàn chỉnh: lăn, rơi, fragile, cầu, 3 switch, tách/nhập; 66 test luật pass; chơi được trong terminal | Trưởng nhóm + AI | `bloxorz/core/rules.py` |
| **Server TCP** | `python -m bloxorz.server` (chạy ở thư mục gốc repo); đã thử GUI online: màn 4 đi 7 nước, tách/nhập, thắng. Solve báo "not implemented yet" cho tới khi có thuật toán | Trưởng nhóm + AI | `bloxorz/server.py` |
| **15 màn chơi** | `levels/level01–15.json` (gọn lại từ 22 màn ngày 2026-10-21): cơ bản 01–03, ô dễ vỡ 04–06, công tắc/cầu 07–09, tách khối 10–12, **màn lớn 13–15**. Màn 06 là màn UCS khác BFS (BFS 21 nước/chi phí 35, UCS 26/30). Màn lớn: 13 *Serpentine hall* (hành lang có cửa cầu, ~17 nghìn trạng thái), 14 *Twin fields* (tách khối trên 2 sân rộng, ~62 nghìn), 15 *Grand tour* (gộp mọi cơ chế, ~254 nghìn; BFS mất vài giây). Màn nào cũng có lời giải ngắn nhất trong `tests/test_golden.py`. Tất cả tự thiết kế | Trưởng nhóm + AI | `levels/` |
| **Đo đạc + biểu đồ** | `benchmark/run_benchmark.py` (trung vị 5 lần chạy, bộ nhớ đỉnh bằng tracemalloc, mỗi lần chạy trong tiến trình riêng có giới hạn 300 s) và `benchmark/plot_results.py` (5 biểu đồ theo nhóm màn; tự chuyển sang thang log khi màn lớn chênh hàng trăm lần) | Trưởng nhóm + AI | `benchmark/`, kết quả ở `results/` |
| **BFS** | Kiểm tra đích khi sinh nút; luôn ra lời giải ít nước nhất | Tú (`tu-bfs`, PR #4) | `bloxorz/search/bfs.py` |
| **DFS** | Stack tường minh + visited; lời giải dài nhưng duyệt ít nút | Mai (`Mai`, PR #5) | `bloxorz/search/dfs.py` |
| **UCS** | Hàng đợi ưu tiên theo chi phí; chi phí tối ưu cả 15 màn | Hoàng (`hoang`, PR #2) | `bloxorz/search/ucs.py` |
| **A\*** | f = g + h, cho mở lại trạng thái khi tìm được đường rẻ hơn (`best_cost`). Heuristic: Manhattan của ô gần đích nhất / 2, +0.5 nếu chưa đứng. Đã kiểm trên mọi trạng thái của bộ 22 màn cũ (gồm các màn tách khối 10–12 hiện tại): **admissible** (0 lần đoán quá) nhưng **không consistent** (vài bước ở màn tách khối), nên báo cáo không được ghi "consistent". Chi phí bằng UCS, duyệt ít nút hơn UCS ở mọi màn. Ở màn tách khối lớn (14, 15) chỉ ít hơn ~15%, vì heuristic yếu khi tách khối; thời gian và bộ nhớ không tốt hơn UCS (tốn thêm tính và lưu h) | LightR / Sang (`LightR`, PR #6) | `bloxorz/search/astar.py`, `heuristics.py` |
| **Số liệu 4 thuật toán** | Đã chạy benchmark 2026-10-21: 15/15 màn × 4 thuật toán đều giải được, lời giải hợp lệ (~3 phút). Màn nhỏ vài ms; màn lớn BFS/UCS/A\* 0.1–4 s, DFS nhanh hơn ~20 lần nhưng lời giải tới 4415 nước (màn 15) | Trưởng nhóm + AI | `results/benchmark.csv`, `results/summary.md`, `results/figures/` (không commit, chạy lại bằng lệnh trong README) |
| **GUI với màn lớn** | Thử với server thật màn 15: camera thu đủ bàn 48 cột; BFS phát lại 72 nước thắng; khi chờ giải có đồng hồ giây; phát lại có **F** tua nhanh (x1/x4/x16) và **Esc** nhảy tới cuối (lệnh server mới `apply`, DFS 4415 nước xong trong vài giây); tự kết nối lại server khi Offline (chưa thử tự động, cần thử tay); màn chọn màn 3 cột = 5 nhóm | Trưởng nhóm + AI | `gui/scripts/main.gd`, `bloxorz/server.py` |
| Khung Python | `level.py`, `state.py`, `render.py`, `cli.py`, `search/common.py` (đo thời gian/bộ nhớ) | AI | `bloxorz/` |
| Unit test | 180 test: bảng lăn, luật, fragile, cầu, 3 switch, permanent, split/merge, lời giải mẫu 15 màn, kiểm tra chéo 4 solver. **180/180 pass** (~35 s; `pytest -q -m "not slow"` bỏ 3 màn lớn, chạy < 1 s) | Trưởng nhóm + AI | `tests/` |
| GUI Godot 4.7.2 | Bàn 3D từ JSON; khối voxel "khỉ lửa" lăn đúng vật lý (giữ hướng xoay); rơi lộn nhào qua mép; tách 2 cube + đổi khối + nhập lại; cầu lật lên/xuống; camera kéo chuột/zoom; HUD voxel; màn chọn màn; TCP client (online) + luật tạm (offline) | Trưởng nhóm + AI | `gui/` |
| Kiểm thử GUI online | Với server giả: load → solve A\* → phát lại 7 nước (tách, đổi khối, nhập, thắng) | AI | — |
| Quy định nhóm + AI | Quy tắc, phân vùng thư mục, quy trình nhánh/PR, việc từng người (4 bạn = 4 thuật toán) | AI | `AGENTS.md`, `CONTRIBUTING.md`, `docs/ONBOARDING.md` |
| Công cụ | Tải Godot đúng bản: `python tools/get_godot.py` | AI | `tools/` |

Nhánh: `main` đã có đủ 4 thuật toán (PR #2, #4, #5, #6); `wuang` đã cập nhật theo `main`. Từ giờ `main` là nhánh chính, thay đổi mới đi qua PR.

## 2. Đang chờ / chưa làm

| Việc | Vai | Trạng thái |
| --- | --- | --- |
| Sửa vặt A\*: docstring complete/optimal/độ phức tạp, chuỗi `"""` lọt giữa `default_heuristic`, gõ sai "mahattan", tên chủ file, dòng trống cuối file | LightR | chưa |
| Mỗi bạn ghi prompt AI đã dùng vào `docs/AI_USAGE.md` | Cả nhóm | chưa |
| Xuất `.exe` GUI + hướng dẫn chạy server trong README | Trưởng nhóm | chưa |
| Báo cáo PDF (phân công + %, mô hình hoá, mỗi thuật toán, thí nghiệm + biểu đồ + nhận xét, tham khảo, phụ lục AI), một ngôn ngữ | Cả nhóm | chưa |
| Quay video YouTube công khai (chơi tay + Solve, có thuyết minh/phụ đề) | Trưởng nhóm | chưa |
| Nộp `MSSV1_MSSV2_...zip` (>20 MB thì Google Drive) | Trưởng nhóm | chưa |

## 3. Quyết định đã chốt (đừng đổi khi chưa hỏi nhóm)

- GUI: Godot 4.7.2 Standard, GDScript. Phong cách voxel cam–vàng–đỏ trên nền tím.
- Luật: switch kích hoạt khi một nước kết thúc trên nó; thứ tự lăn → kiểm tra đỡ → switch → kiểm tra lại; cầu đóng dưới khối thì rơi; cube đơn đứng được trên fragile, chỉ bấm soft switch, không thắng; `SWITCH` là action cost 1.
- Cost: lăn 1, kết thúc nằm trên fragile 2, `SWITCH` 1 (mọi cost ≥ 1).
- Benchmark chạy không mở GUI; solver không giới hạn thời gian; benchmark giới hạn an toàn 300 s mỗi (màn, thuật toán), thời gian lấy trung vị 5 lần.
- 15 màn, 5 nhóm × 3: cơ bản, dễ vỡ, công tắc, tách khối, màn lớn (`group: "hard"`). Không thêm màn lặt vặt.
- Dùng DFS (không phải IDS).
- `expanded` đếm khi lấy nút ra và mở rộng; không đếm nút đích (thống nhất cả 4 thuật toán).

## 4. Câu hỏi còn mở

- Kênh nộp bài và yêu cầu riêng của lab instructor.
- Đầu khối khi đứng: giữ vật lý thật (có thể lộn ngược) — hiện đang dùng — hay luôn dựng nhân vật đầu trên.

## 5. Cách tiếp tục (cho người và AI)

1. Đọc file này → `AGENTS.md` → `docs/ONBOARDING.md`.
2. `git pull`, `pytest -q` để xem test nào còn fail (đó là việc còn lại).
3. Chạy GUI: `tools\godot\Godot_v4.7.2-stable_win64.exe --path gui` (hoặc `D:\Tools\Godot\...` trên máy trưởng nhóm).
4. Xong một mốc → cập nhật bảng mục 2.
