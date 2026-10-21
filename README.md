# Project 1 — Bloxorz Solvers (CSC14003, FIT-HCMUS)

Game Bloxorz 3D (Godot 4) và 4 thuật toán tìm kiếm tự cài bằng Python: **BFS, DFS, UCS, A\***.

## Chạy nhanh (người chấm)

Cần **Windows 10/11 64-bit** và **Python 3.10+** trong PATH (đã thử với 3.13). Phần luật và thuật toán chỉ dùng thư viện chuẩn.

1. Tải **`Bloxorz.exe`** (~105 MB) từ link Google Drive trong báo cáo, đặt vào `gui\export\Bloxorz.exe`.
2. Nhấp đúp **`run.bat`** ở thư mục gốc: mở cửa sổ server Python, rồi mở game 3D.
   Không muốn tải `.exe`: chạy `python tools/get_godot.py` (tải Godot 4.7.2, ~86 MB) rồi `tools\godot\Godot_v4.7.2-stable_win64.exe --path gui` sau khi đã bật `python -m bloxorz.server`.
3. Trong game: **LEVELS** chọn màn (15 màn, 5 nhóm), mũi tên/WASD để chơi, các nút **BFS / DFS / UCS / A\*** để máy giải và tự lăn tới đích. Khi đang phát lại: **F** tua nhanh, **Esc** nhảy tới cuối.
4. Góc HUD phải hiện `● Python server`. Nếu hiện `○ Offline`: kiểm tra cửa sổ server còn chạy, rồi bấm RESTART.

Không cần GUI: `python -m bloxorz solve levels/level01.json --algo astar` (xem bảng "Chạy" bên dưới). Chạy lại toàn bộ thí nghiệm: `pip install -r requirements.txt` rồi `python benchmark/run_benchmark.py` (~3 phút) và `python benchmark/plot_results.py`.

## Cấu trúc

```text
bloxorz/        Python: luật game (core/) + solver (search/) + TCP server
gui/            Godot 4: giao diện 3D
levels/         màn chơi JSON
tests/          pytest
benchmark/      chạy thí nghiệm cho báo cáo
docs/           luật, định dạng JSON, kiến trúc, cách test, kế hoạch
```

## Bắt đầu

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
pytest -q
python -m bloxorz show levels/level01.json
```

**Thành viên mới: đọc [docs/ONBOARDING.md](docs/ONBOARDING.md) trước.** Đọc tiếp: [AGENTS.md](AGENTS.md) (quy định chung, cả cho AI) → [docs/TESTING.md](docs/TESTING.md) → [CONTRIBUTING.md](CONTRIBUTING.md).

## Chạy

| Việc | Lệnh |
| --- | --- |
| Xem màn chơi | `python -m bloxorz show levels/level01.json` |
| Chơi trong terminal | `python -m bloxorz play levels/level01.json` |
| Giải | `python -m bloxorz solve levels/level01.json --algo astar` |
| Kiểm chứng lời giải | `python -m bloxorz verify levels/level01.json results/x.json` |
| Server cho GUI | `python -m bloxorz.server --port 5555` |
| Đo đạc (không mở GUI) | `python benchmark/run_benchmark.py` → `results/benchmark.csv`, `results/summary.md` |
| Vẽ biểu đồ | `python benchmark/plot_results.py` → `results/figures/*.png` |
| GUI (bản xuất) | `run.bat`, hoặc tự bật server rồi mở `gui\export\Bloxorz.exe` |
| GUI (mã nguồn) | Mở `gui/project.godot` bằng **Godot 4.7.2** (xem [gui/README.md](gui/README.md)) |

## Xuất file .exe (trưởng nhóm)

```bash
python tools/get_godot.py --templates
tools\godot\Godot_v4.7.2-stable_win64_console.exe --headless --path gui --export-release "Windows Desktop" export/Bloxorz.exe
```

Lệnh 1 tải Godot và export templates (~1 GB, chỉ giữ 2 file Windows vào `tools/godot/templates/`, không commit). Lệnh 2 tạo `gui/export/Bloxorz.exe` (một file, đã gói sẵn dữ liệu). Thư mục `gui/export/` không commit. Khi nộp: zip chính (mã nguồn + báo cáo) không kèm `.exe`; `.exe` để riêng trên Google Drive, link ghi trong báo cáo. File `.exe` tự tìm thư mục `levels/` ở các thư mục cha, nên phải để nguyên cấu trúc repo.

## Tham khảo

- Bloxorz — Coolmath Games: https://www.coolmathgames.com/0-bloxorz
- Russell & Norvig, *Artificial Intelligence: A Modern Approach*, 4th ed., chương 3.
