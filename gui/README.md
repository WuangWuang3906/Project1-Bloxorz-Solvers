# GUI — Godot 4 (Trưởng nhóm)

- Phong cách đã chốt: mức "7/10" — ô bo góc, bóng đổ mềm, màu riêng từng loại ô, glow nhẹ cho switch/goal, khối lăn qua cạnh, bảng nút kính mờ.
- Tạo project Godot 4 tại thư mục này (`gui/project.godot`). Không commit `gui/.godot/`.
- Godot chỉ **vẽ**: mọi luật lấy từ Python qua TCP (`docs/ARCHITECTURE.md` mục 3).
- Khi server chưa xong: đọc trực tiếp `levels/*.json` để dựng bàn, và `results/sample/*.json` để thử hoạt ảnh Solve.

## Việc cần làm

- [ ] Dựng bàn từ JSON (floor, void, fragile, bridge mở/đóng, 3 loại switch, goal)
- [ ] Khối 1×1×2 và hoạt ảnh lăn quanh cạnh (`Tween`)
- [ ] Camera tự vừa màn; phím xoay camera
- [ ] Nút New Game, Restart, chọn màn, Solve BFS/DFS/UCS/A\*; bảng số liệu
- [ ] Kết nối TCP (`StreamPeerTCP`), phát lại lời giải từng bước
- [ ] Hiệu ứng rơi, cầu trượt, tách/nhập khối
