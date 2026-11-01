# Project 1 — Bloxorz Solvers (CSC14003, FIT-HCMUS)

## Giới thiệu

Đồ án 1 môn **Cơ sở Trí tuệ Nhân tạo (CSC14003)**, Trường ĐH Khoa học Tự nhiên – ĐHQG-HCM. Nhóm viết lại trò chơi **Bloxorz** với giao diện 3D và cài đặt 4 thuật toán tìm kiếm để máy tự giải: **BFS, DFS, UCS, A\***.

- Đầy đủ cơ chế: khối 1×1×2 ba tư thế, ô dễ vỡ, cầu, công tắc soft/heavy (toggle hoặc mở/đóng cố định), công tắc tách khối và nhập khối.
- **15 màn** do nhóm tự thiết kế, chia 5 nhóm: cơ bản, ô dễ vỡ, công tắc & cầu, tách khối, màn lớn.
- Bấm một thuật toán, game hiện tiến độ, rồi khối tự lăn tới đích theo lời giải; có bảng số liệu (số nước, số nút mở rộng, thời gian, bộ nhớ đỉnh).

| Phần | Ngôn ngữ / công cụ |
| --- | --- |
| Luật chơi, 4 thuật toán, server | **Python 3.10+** (chỉ thư viện chuẩn) |
| Giao diện 3D | **Godot 4.7.2**, GDScript |
| Giao tiếp | TCP `127.0.0.1:5555`, mỗi dòng một JSON |
| Test, thực nghiệm | `pytest`, `matplotlib` |

## Video demo

Link YouTube: https://youtu.be/PRtVNUqQWWY

## Thành viên

| MSSV | Họ và tên | Vai trò |
| --- | --- | --- |
| 24120221 | Trần Công Quang | Trưởng nhóm: luật chơi (`bloxorz/core/`), GUI Godot, server, 15 màn chơi, unit test, thực nghiệm, video, ghép báo cáo |
| 24120152 | Trần Ngọc Thanh Tú | BFS (`bloxorz/search/bfs.py`) và phần BFS trong báo cáo |
| 24120199 | Trịnh Kim Mai | DFS (`bloxorz/search/dfs.py`) và phần DFS trong báo cáo |
| 24120181 | Huỳnh Huy Hoàng | UCS (`bloxorz/search/ucs.py`), hàm chi phí và phần UCS trong báo cáo |
| 24120132 | Phạm Nguyễn Quang Sáng | A\* và heuristic (`bloxorz/search/astar.py`, `heuristics.py`) và phần A\* trong báo cáo |

## Chạy từ đầu (máy chưa có gì)

**Bước 1. Cài đặt:** [Python 3.10+](https://www.python.org/downloads/) (Windows: tick *Add python.exe to PATH*) và [Git](https://git-scm.com/downloads).

**Bước 2. Tải mã nguồn:**

```bash
git clone https://github.com/WuangWuang3906/Project1-Bloxorz-Solvers.git
cd Project1-Bloxorz-Solvers
```

**Bước 3. Môi trường ảo và thư viện** (chỉ cần cho test và biểu đồ; game và thuật toán chạy được không cần bước này):

```bash
python -m venv .venv
```

- Windows: `.venv\Scripts\activate`
- macOS / Linux: `source .venv/bin/activate` (dùng `python3` thay `python` nếu máy không có lệnh `python`)

```bash
pip install -r requirements.txt
```

**Bước 4. Kiểm tra:** `pytest -q -m "not slow"` phải báo toàn bộ *passed*.

**Bước 5. Mở giao diện:** Windows dùng **Cách 1** (`.exe`); macOS, Linux (hoặc Windows bị chặn `.exe`) dùng **Cách 2** (Godot).

## Cách 1 — Windows: chạy file `.exe`

1. Tải **`Bloxorz.exe`** (~105 MB): https://drive.google.com/file/d/1-p3JeccLZsZWYPmOLMdXkbuCNvejvZwJ/view
2. Đặt file vào **`gui\export\Bloxorz.exe`** trong thư mục mã nguồn này.
3. Nhấp đúp `gui\export\Bloxorz.exe` (hoặc `run.bat` ở thư mục gốc). Game **tự bật server Python** và tự tắt khi đóng game. Góc trên phải hiện `● Python server` là đúng.

Lưu ý:
- `.exe` đặt ở chỗ khác (ví dụ Downloads): vẫn chơi tay được 15 màn, nhưng game báo *"Không thấy mã nguồn Python — hãy đọc README…"* và khoá các nút giải.
- Nhấp đúp mà **không có gì xảy ra**: máy đang bật **Smart App Control** / Application Control của Windows, chặn mọi `.exe` không có chữ ký số (file của nhóm không ký số). Dùng **Cách 2**.
- Hiện `○ Offline`: kiểm tra lệnh `python` chạy được trong terminal, hoặc tự bật `python -m bloxorz.server` ở thư mục gốc rồi bấm RESTART.

## Cách 2 — Mọi hệ điều hành (macOS, Linux, Windows): chạy bằng Godot

File `.exe` chỉ chạy trên Windows; **macOS và Linux** chạy GUI từ mã nguồn:

1. Tải **Godot 4.7.2 (bản Standard, không phải .NET)** cho hệ điều hành của mình: https://godotengine.org/download/archive/ (chọn 4.7.2-stable).
   Trên Windows có thể dùng lệnh: `python tools/get_godot.py` (tải vào `tools/godot/`).
2. Mở terminal ở **thư mục gốc** của mã nguồn, bật server (để cửa sổ này chạy):
   ```bash
   python -m bloxorz.server
   ```
   macOS/Linux dùng `python3` nếu máy không có lệnh `python`.
3. Mở game:
   - **Cách dễ:** mở Godot → *Import* → chọn `gui/project.godot` → bấm **Run** (F5).
   - **Dòng lệnh:**
     - Windows: `tools\godot\Godot_v4.7.2-stable_win64.exe --path gui`
     - macOS: `/Applications/Godot.app/Contents/MacOS/Godot --path gui`
     - Linux: `./Godot_v4.7.2-stable_linux.x86_64 --path gui`
4. macOS lần đầu có thể báo *"không thể mở vì không xác minh được nhà phát triển"*: chuột phải vào Godot.app → **Open** → Open.

## Trong game

- **LEVELS**: chọn màn (15 màn, 5 nhóm). **Nút HƯỚNG DẪN** (góc dưới phải): xem toàn bộ phím. **Nút CÀI ĐẶT**: đổi màu ô công tắc Đậm / Nhạt.
- **Phím mũi tên**: lăn khối (không dùng WASD vì Unikey/Telex làm sai phím chữ). **Tab/Space**: đổi khối khi đã tách. **R**: chơi lại. **F11**: toàn màn hình.
- **BFS / DFS / UCS / A\***: máy giải (bảng chờ hiện % tiến độ) rồi khối tự lăn tới đích. Khi phát lại: **F** tua nhanh, **Esc** nhảy tới cuối. R / RESTART / đổi màn / bấm thuật toán khác huỷ ngay việc đang chạy.

## Không cần GUI (mọi hệ điều hành)

| Việc | Lệnh |
| --- | --- |
| Xem màn chơi | `python -m bloxorz show levels/level01.json` |
| Chơi trong terminal | `python -m bloxorz play levels/level01.json` |
| Giải và xem từng bước | `python -m bloxorz solve levels/level06.json --algo ucs --replay` |
| Kiểm chứng lời giải | `python -m bloxorz verify levels/level01.json results/x.json` |
| Chạy toàn bộ test | `pytest -q` (bỏ 3 màn lớn cho nhanh: `pytest -q -m "not slow"`) |
| Thực nghiệm (15 màn × 4 thuật toán, ~4 phút) | `python benchmark/run_benchmark.py` → `results/benchmark.csv`, `results/summary.md` |
| Vẽ biểu đồ | `python benchmark/plot_results.py` → `results/figures/*.png` |
| Thử trọng số ô dễ vỡ (lý do chọn 2) | `python benchmark/cost_weights.py` → `results/cost_weights.md` |
| Đếm số trạng thái mỗi màn | `python tools/count_states.py` |

`--algo` nhận `bfs`, `dfs`, `ucs`, `astar`.

## Cấu trúc

```text
bloxorz/        Python: luật game (core/), 4 thuật toán (search/), TCP server
gui/            Godot 4: giao diện 3D
levels/         15 màn chơi JSON
tests/          pytest
benchmark/      thực nghiệm và biểu đồ cho báo cáo
docs/           luật, định dạng JSON, kiến trúc, cách test, kế hoạch
tools/          tải Godot, xuất .exe, đếm trạng thái
```

Thành viên đọc thêm: [docs/ONBOARDING.md](docs/ONBOARDING.md), [AGENTS.md](AGENTS.md), [docs/GAME_RULES.md](docs/GAME_RULES.md), [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

## Xuất file .exe (chỉ Windows, trưởng nhóm)

```bash
python tools/get_godot.py --templates
python tools/build_exe.py
```

Tạo `gui/export/Bloxorz.exe` và `Bloxorz.zip` (không commit, chia sẻ qua Google Drive). Godot cài ở chỗ khác thì đặt biến `GODOT` trỏ tới file `..._console.exe`.

## Tham khảo

- Bloxorz (game gốc) — Coolmath Games: https://www.coolmathgames.com/0-bloxorz (chỉ tham khảo luật; 15 màn do nhóm tự thiết kế)
- Russell & Norvig, *Artificial Intelligence: A Modern Approach*, 4th ed., chương 3.
- Godot Engine 4.7: https://godotengine.org
