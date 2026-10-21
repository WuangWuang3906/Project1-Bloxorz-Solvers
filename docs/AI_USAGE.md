# Nhật ký sử dụng AI (cho Phụ lục báo cáo)

Đề yêu cầu phụ lục mô tả cách dùng Generative AI và prompt đã dùng (tr. 7). Mỗi người tự ghi phần của mình.

| Ngày | Thành viên | Công cụ | Mục đích | Prompt chính (tóm tắt) | Mình đã kiểm tra/sửa gì |
| --- | --- | --- | --- | --- | --- |
| 2026-10-14 | Trưởng nhóm | Claude | Dựng khung repo, quy định, tài liệu luật, unit test | "Tạo rule, quy định và agent cho AI của các thành viên đọc..." | Duyệt luật, chạy test |
| 2026-10-20 | Tú (TV2) | Codex (GPT-5) | Review và kiểm thử thuật toán BFS; hỗ trợ thiết lập Python/pytest | "Review code BFS, kiểm tra tính đúng đắn và chạy test cho solver Bloxorz" | Đọc và đối chiếu `bfs.py` với cấu trúc state/rules; kiểm tra FIFO, visited, parent, truy vết đường đi và chi phí; chạy 3 smoke test cô lập đều đạt; chạy test solver/golden và xác định 25 lỗi đến từ `core/rules.py` chưa triển khai, không phải từ BFS |
