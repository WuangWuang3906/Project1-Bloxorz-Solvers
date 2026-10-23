# Nhật ký sử dụng AI (cho Phụ lục báo cáo)

Đề yêu cầu phụ lục mô tả cách dùng Generative AI và prompt đã dùng (tr. 7). Mỗi người tự ghi phần của mình.

| Ngày | Thành viên | Công cụ | Mục đích | Prompt chính (tóm tắt) | Mình đã kiểm tra/sửa gì |
| --- | --- | --- | --- | --- | --- |
| 2026-10-14 | Trưởng nhóm | Claude | Dựng khung repo, quy định, tài liệu luật, unit test | "Tạo rule, quy định và agent cho AI của các thành viên đọc..." | Duyệt luật, chạy test |
| 2026-10-20 | Tú (TV2) | Codex (GPT-5) | Review và kiểm thử thuật toán BFS; hỗ trợ thiết lập Python/pytest | "Review code BFS, kiểm tra tính đúng đắn và chạy test cho solver Bloxorz" | Đọc và đối chiếu `bfs.py` với cấu trúc state/rules; kiểm tra FIFO, visited, parent, truy vết đường đi và chi phí; chạy 3 smoke test cô lập đều đạt; chạy test solver/golden và xác định 25 lỗi lúc đó đến từ `core/rules.py` chưa triển khai, không phải từ BFS. Cập nhật 2026-10-21: rules đã xong, toàn bộ test BFS pass |
| 2026-10-14 | Trưởng nhóm | Claude | GUI Godot 3D (bàn, khối voxel, lăn, rơi, camera, HUD) | "Làm GUI 3D đẹp bằng Godot, khối lăn đúng vật lý, kéo chuột xoay camera" | Chơi thử từng màn; phát hiện mặt khối bị lật sai sau khi lăn và yêu cầu sửa; chỉnh mức độ đẹp "7/10" |
| 2026-10-15 | Trưởng nhóm | Claude | Cài `bloxorz/core/rules.py` (lăn, fragile, cầu, 3 loại switch, tách/nhập) và TCP server | "Chúng ta là người viết rules luôn", "làm server.py" | Chạy 66 test luật; chơi trong terminal và GUI online |
| 2026-10-15 | Trưởng nhóm | Claude | Thiết kế màn chơi, kiểm tra màn nào cũng giải được | "Thêm màn, màn nào cũng phải dùng cơ chế của nhóm" | Dùng solver kiểm tra lời giải; sửa các màn không giải được |
| 2026-10-20 | Trưởng nhóm | Claude | Review nhánh BFS/DFS/UCS/A\* của các bạn; benchmark + biểu đồ | "Chuyển sang nhánh ... và review", "thực hiện benchmark" | Chạy toàn bộ test; kiểm tra heuristic A\* (bản đầu) trên mọi trạng thái (admissible, không consistent) |
| 2026-10-21 | Trưởng nhóm | Claude | Gọn còn 15 màn + 3 màn lớn; GUI tua nhanh/bỏ qua phát lại, tự kết nối lại; xuất .exe, `run.bat` | "Thêm 2-3 màn lớn, khó, down về còn 15 màn", "bước (c) cả ba luôn" | Chạy GUI thật với màn 15 (BFS phát lại 72 nước, DFS bỏ qua bằng Esc); 182 test pass |
| 2026-10-20 | Sáng (TV4) | Claude | Review và kiểm tra tính đúng đắn, bổ sung nếu thiếu cho hàm heuristic | "Review hàm default_heuristic"; "Check code astar và bổ sung nếu thiếu" | Kiểm tra logic thuật toán A\*; kiểm tra lại tính đúng đắn khi chạy của `heuristics.py` và `astar.py` |
| 2026-10-22 | Sáng (TV4) | Claude | Heuristic còn chưa tối ưu khi khối đi với tốc độ 1,5 ô/nước và có thể tách; gợi ý logic tối ưu hơn (không cần chính xác, giữ dễ hiểu, đơn giản) | "Check code hàm heuristic" | Heuristic mới: trưởng nhóm kiểm tra trên mọi trạng thái của 15 màn — admissible và consistent, A\* vẫn tối ưu, duyệt ít nút hơn bản cũ |
