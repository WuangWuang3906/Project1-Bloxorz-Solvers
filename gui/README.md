# GUI — Godot 4 (Trưởng nhóm)

**Phiên bản bắt buộc: Godot 4.7.2-stable, bản Standard (không phải .NET).** Cả nhóm dùng đúng bản này để file project không bị nâng cấp lệch.
Tải: https://github.com/godotengine/godot/releases/tag/4.7.2-stable → `Godot_v4.7.2-stable_win64.exe.zip`. Giải nén là chạy, không cần cài.
Cách nhanh nhất: `python tools/get_godot.py` (tự tải đúng bản, kiểm tra checksum, giải nén vào `tools/godot/`).
Chỉ người làm GUI và người quay video cần Godot; người làm thuật toán chỉ cần Python.

## Chạy GUI

```powershell
tools\godot\Godot_v4.7.2-stable_win64.exe --path gui
```

Hoặc mở Godot, Import → chọn `gui/project.godot` → F5. Phím: mũi tên/WASD lăn, Q/E xoay camera, R chơi lại.

Kiểm tra tự động (chụp ảnh sau khi đi các nước):

```powershell
tools\godot\Godot_v4.7.2-stable_win64_console.exe --path gui -- --level=0 --moves=RDDRRDR --screenshot=shot.png
```

## Trạng thái hiện tại: offline mode

Server Python chưa có nên GUI tạm dùng `scripts/offline_rules.gd` (bản sao luật cơ bản, **không** có split). Nút Solve phát lại file `results/sample/levelXX_<algo>.json` nếu có. Khi `bloxorz/server.py` xong sẽ chuyển sang TCP và bỏ offline rules.

| File | Vai trò |
| --- | --- |
| `scripts/main.gd` | dựng môi trường, camera, luồng game, input, chế độ tự động |
| `scripts/board.gd` | dựng ô 3D từ JSON, hoạt ảnh cầu |
| `scripts/block.gd` | khối, hoạt ảnh lăn/rơi/chìm |
| `scripts/game_ui.gd` | HUD |
| `scripts/level_data.gd` | đọc JSON màn chơi |
| `scripts/offline_rules.gd` | luật tạm (sẽ bỏ) |
| `scripts/mesh_util.gd` | mesh bo góc, vật liệu |

- Phong cách đã chốt: mức "7/10" — ô bo góc, bóng đổ mềm, màu riêng từng loại ô, glow nhẹ cho switch/goal, khối lăn qua cạnh, bảng nút kính mờ.
- Tạo project Godot 4 tại thư mục này (`gui/project.godot`). Không commit `gui/.godot/`.
- Godot chỉ **vẽ**: mọi luật lấy từ Python qua TCP (`docs/ARCHITECTURE.md` mục 3).
- Khi server chưa xong: đọc trực tiếp `levels/*.json` để dựng bàn, và `results/sample/*.json` để thử hoạt ảnh Solve.

## Việc cần làm

- [x] Dựng bàn từ JSON (floor, void, fragile, bridge mở/đóng, 3 loại switch, goal)
- [x] Khối 1×1×2 và hoạt ảnh lăn quanh cạnh (`Tween`)
- [x] Camera tự vừa màn; phím xoay camera
- [~] Nút New Game, Restart, chọn màn, Solve BFS/DFS/UCS/A\*; bảng số liệu
- [ ] Kết nối TCP (`StreamPeerTCP`), phát lại lời giải từng bước
- [ ] Hiệu ứng rơi, cầu trượt, tách/nhập khối
