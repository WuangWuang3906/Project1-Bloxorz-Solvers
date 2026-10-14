# Trạng thái dự án (cập nhật 2026-10-14)

> File này là "bộ nhớ" của nhóm và của AI. **Đọc đầu tiên khi tiếp tục làm việc**, và cập nhật mỗi khi xong một mốc.

## 1. Đã xong

| Hạng mục | Kết quả | Ai | Nơi |
| --- | --- | --- | --- |
| Đọc đề + FAQ lớp | GUI phải 3D; GUI ngôn ngữ gì cũng được, thuật toán bằng Python; Solve phải cho khối tự lăn tới đích; ≥ 10 test case | Trưởng nhóm | đề `AI - Project 1.pdf` (ngoài repo) |
| Chốt luật, cost, JSON | Luật mục mơ hồ đã tự chốt theo game gốc | Trưởng nhóm + AI | `docs/GAME_RULES.md`, `docs/JSON_FORMAT.md` |
| Kiến trúc | Python = luật + solver (nguồn duy nhất); Godot chỉ vẽ; TCP 127.0.0.1:5555 | Trưởng nhóm + AI | `docs/ARCHITECTURE.md` |
| Khung Python | `level.py`, `state.py`, `render.py`, `cli.py`, `search/common.py` (đo thời gian/bộ nhớ) chạy được; phần luật và 4 solver để trống có TODO | AI | `bloxorz/` |
| Unit test | 91 test: bảng lăn, luật, fragile, cầu, 3 switch, permanent, split/merge, lời giải mẫu, kiểm tra chéo 4 solver. Đã kiểm chứng bằng bản cài đặt tham khảo riêng (không đưa vào repo): 91/91 pass | Trưởng nhóm + AI | `tests/` |
| Màn mẫu | 4 màn: basic, fragile, switch, split | AI | `levels/level01–04.json` |
| GUI Godot 4.7.2 | Bàn 3D từ JSON; khối voxel "khỉ lửa" lăn đúng vật lý (giữ hướng xoay); rơi lộn nhào qua mép; tách 2 cube + đổi khối + nhập lại; cầu lật lên/xuống; camera kéo chuột/zoom; HUD voxel; màn chọn màn; TCP client (online) + luật tạm (offline) | Trưởng nhóm + AI | `gui/` |
| Kiểm thử GUI online | Với server giả: load → solve A\* → phát lại 7 nước (tách, đổi khối, nhập, thắng) | AI | — |
| Quy định nhóm + AI | Quy tắc, phân vùng thư mục, quy trình nhánh/PR, việc từng vai | AI | `AGENTS.md`, `CONTRIBUTING.md`, `docs/ONBOARDING.md` |
| Công cụ | Tải Godot đúng bản: `python tools/get_godot.py` | AI | `tools/` |

Nhánh: code mới nhất của trưởng nhóm ở `wuang` (đã push). **Chưa merge vào `main`** — cần mở Pull Request.

## 2. Đang chờ / chưa làm

| Việc | Vai | Hạn | Trạng thái |
| --- | --- | --- | --- |
| Gán tên vai A–D, mời thành viên, PR `wuang` → `main` | Trưởng nhóm | 15/10 | chưa |
| `roll()` → luật cơ bản → cầu/switch → split (`bloxorz/core/rules.py`) | A | 16 → 17 → 19 → 23/10 | chưa bắt đầu |
| BFS, DFS/IDS | B | 21/10 | chưa bắt đầu |
| UCS, A\*, heuristic (cả khi split) | C | 21/10, 25/10 | chưa bắt đầu |
| `server.py`; 20 màn; benchmark; biểu đồ | D | 19, 24, 26, 28/10 | chưa bắt đầu |
| Nối GUI với server thật, xoá `gui/scripts/offline_rules.gd` | Trưởng nhóm | sau khi D xong server | chờ |
| Xuất `.exe`, quay video YouTube, phần GUI/kiểm thử trong báo cáo | Trưởng nhóm | 30/10 | chưa |
| Báo cáo PDF (phân công + %, mô hình hoá, thí nghiệm, tham khảo, phụ lục AI) | Cả nhóm | 29/10 | chưa |
| Nộp `MSSV1_MSSV2_...zip` | Trưởng nhóm | **trước 12:00 1/11** (hạn cứng 22:00) | chưa |

## 3. Quyết định đã chốt (đừng đổi khi chưa hỏi nhóm)

- GUI: Godot 4.7.2 Standard, GDScript. Phong cách voxel cam–vàng–đỏ trên nền tím.
- Luật: switch kích hoạt khi một nước kết thúc trên nó; thứ tự lăn → kiểm tra đỡ → switch → kiểm tra lại; cầu đóng dưới khối thì rơi; cube đơn đứng được trên fragile, chỉ bấm soft switch, không thắng; `SWITCH` là action cost 1.
- Cost: lăn 1, kết thúc nằm trên fragile 2, `SWITCH` 1 (mọi cost ≥ 1).
- Benchmark chạy không mở GUI; solver không giới hạn thời gian, benchmark có giới hạn an toàn (chưa chốt con số).
- 20 màn: 4 nhóm × 5.

## 4. Câu hỏi còn mở

- Giới hạn an toàn cho benchmark (đề xuất 300 s hoặc 5 triệu node).
- Dùng DFS hay IDS (B quyết, ghi trong báo cáo).
- Kênh nộp bài và yêu cầu riêng của lab instructor.
- Đầu khối khi đứng: giữ vật lý thật (có thể lộn ngược) — hiện đang dùng — hay luôn dựng nhân vật đầu trên.

## 5. Cách tiếp tục (cho người và AI)

1. Đọc file này → `AGENTS.md` → `docs/ONBOARDING.md`.
2. `git pull`, `pytest -q` để xem test nào còn fail (đó là việc còn lại).
3. Chạy GUI: `tools\godot\Godot_v4.7.2-stable_win64.exe --path gui` (hoặc `D:\Tools\Godot\...` trên máy trưởng nhóm).
4. Xong một mốc → cập nhật bảng mục 2.
