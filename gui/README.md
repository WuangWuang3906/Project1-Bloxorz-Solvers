# GUI — Godot 4 (Trưởng nhóm)

**Phiên bản bắt buộc: Godot 4.7.2-stable, bản Standard (không phải .NET).** Cả nhóm dùng đúng bản này để file project không bị nâng cấp lệch.
Tải: https://github.com/godotengine/godot/releases/tag/4.7.2-stable → `Godot_v4.7.2-stable_win64.exe.zip`. Giải nén là chạy, không cần cài.
Cách nhanh nhất: `python tools/get_godot.py` (tự tải đúng bản, kiểm tra checksum, giải nén vào `tools/godot/`).
Chỉ người làm GUI và người quay video cần Godot; người làm thuật toán chỉ cần Python.

## Chạy GUI

```powershell
tools\godot\Godot_v4.7.2-stable_win64.exe --path gui
```

Hoặc mở Godot, Import → chọn `gui/project.godot` → F5.

| Điều khiển | Phím / chuột |
| --- | --- |
| Lăn khối | mũi tên / WASD |
| Đổi khối khi đã tách | Tab / Space |
| Xoay góc nhìn | giữ chuột (trái/phải/giữa) và kéo |
| Zoom | con lăn chuột |
| Xoay 90° / về góc mặc định | Q, E / Home |
| Chơi lại | R |
| Khi đang phát lại lời giải: tua nhanh x1 → x4 → x16 | F |
| Khi đang phát lại lời giải: bỏ qua, nhảy tới cuối | Esc |

Kiểm tra tự động (chụp ảnh rồi thoát), tham số sau `--`:

```powershell
tools\godot\Godot_v4.7.2-stable_win64_console.exe --path gui -- --level=3 --solve=astar --screenshot=shot.png
```

`--level=N` (0-based), `--moves=RRDT` (`T` = đổi khối), `--solve=bfs|dfs|ucs|astar`, `--shot-at=GIÂY` (chụp giữa nước cuối), `--skip-at=GIÂY` (giả lập Esc sau GIÂY giây phát lại), `--yaw/--pitch/--zoom`, `--select`.

## Hai chế độ

- **Online** (góc HUD hiện `● Python server`): khi `python -m bloxorz.server` đang chạy ở **thư mục gốc repo**, cổng 5555. Mọi nước đi và Solve đều hỏi Python. Khi chờ giải, thanh trạng thái đếm giây (màn 15 BFS mất khoảng 15 giây vì server đo cả bộ nhớ).
- **Offline** (`○ Offline`): không có server. GUI dùng `scripts/offline_rules.gd` (bản sao tạm của luật, có cả tách/nhập khối) và nút Solve phát lại `results/sample/levelXX_<algo>.json`. Lỡ mở game trước server thì không cần tắt game: bật server rồi bấm RESTART, chọn một màn hoặc bấm một nút Solve, game tự kết nối lại.

Đã thử với server thật (2026-10-21): màn 15 *Grand tour* — BFS phát lại trọn 72 nước (tách, đổi khối, nhập, thắng); DFS 4415 nước bỏ qua bằng Esc, tới đích đúng.

| File | Vai trò |
| --- | --- |
| `scripts/main.gd` | môi trường, camera (kéo chuột/zoom), luồng game, online/offline, tham số tự động |
| `scripts/board.gd` | dựng ô 3D từ JSON, hoạt ảnh cầu lật lên/xuống |
| `scripts/block.gd` | khối: lăn, rơi lộn nhào qua mép, tách thành 2 khối nhỏ, chìm vào đích |
| `scripts/block_skin.gd` | ngoại hình voxel "khỉ lửa": nắp hoa văn lửa, mặt pixel, đế trắng (vẽ bằng lưới ký tự) |
| `scripts/game_ui.gd` | HUD và màn hình chọn màn |
| `scripts/net_client.gd` | TCP client theo `docs/ARCHITECTURE.md` mục 3 |
| `scripts/level_data.gd` | đọc JSON màn chơi |
| `scripts/offline_rules.gd` | luật tạm (sẽ bỏ) |
| `scripts/mesh_util.gd` | mesh bo góc, vật liệu |

## Việc cần làm

- [x] Dựng bàn từ JSON (floor, void, fragile, bridge mở/đóng, 3 loại switch, goal)
- [x] Khối 1×1×2 và hoạt ảnh lăn quanh cạnh (`Tween`)
- [x] Camera tự vừa màn; phím xoay camera
- [x] Nút New Game, Restart, chọn màn, Solve BFS/DFS/UCS/A\*; bảng số liệu
- [x] Kết nối TCP (`StreamPeerTCP`), phát lại lời giải từng bước
- [x] Hiệu ứng rơi, cầu trượt, tách/nhập khối
