# Test khi chưa có GUI

Toàn bộ luật và solver nằm trong Python, nên **không cần GUI** để phát triển và kiểm tra. GUI chỉ là lớp hiển thị.

## 1. Cài đặt

```bash
python -m venv .venv
.venv\Scripts\activate          # Windows
pip install -r requirements.txt
```

## 2. Năm cách test

### a) Unit test — `pytest -q`

| File | Kiểm tra |
| --- | --- |
| `tests/test_level.py` | đọc JSON màn chơi |
| `tests/test_roll.py` | 12 ô của bảng lăn |
| `tests/test_rules.py` | rơi khỏi bàn, fragile, cầu, switch, thắng |
| `tests/test_golden.py` | lời giải mẫu hợp lệ; BFS cho đúng độ dài ngắn nhất đã biết |
| `tests/test_solvers.py` | 4 solver đều tìm ra lời giải hợp lệ; BFS = IDS = độ dài tối ưu; A\* cost = UCS cost |

Test của phần chưa viết sẽ **fail** cho tới khi phần đó xong — đó là danh sách việc cần làm. Chạy riêng một file: `pytest tests/test_roll.py -q`.

### b) Xem bàn cờ bằng chữ

```bash
python -m bloxorz show levels/level03.json
```

Ký hiệu: `[]` khối, `##` floor, `ff` fragile, `GG` goal, `==` cầu mở, `..` cầu đóng, `so`/`hx`/`sp` switch.

### c) Chơi tay trong terminal

```bash
python -m bloxorz play levels/level01.json
```

Gõ `w a s d` (lên/trái/xuống/phải), `tab` để `SWITCH`, `r` chơi lại, `q` thoát; Enter sau mỗi lệnh. Dùng để kiểm tra luật bằng mắt trước khi viết solver.

### d) Chạy solver và xem lại từng bước

```bash
python -m bloxorz solve levels/level01.json --algo bfs --replay
python -m bloxorz solve levels/level01.json --algo astar --out results/level01_astar.json
```

In ra danh sách action, số liệu đo và (với `--replay`) bàn cờ sau mỗi bước.

### e) Kiểm chứng file kết quả

```bash
python -m bloxorz verify levels/level01.json results/level01_astar.json
```

Chạy lại các action trên bộ luật: mọi bước phải hợp lệ và kết thúc đứng trên goal.

## 3. Kiểm tra chéo giữa các thuật toán

- BFS và IDS: cùng **độ dài** (tối ưu số action).
- UCS và A\*: cùng **cost** (tối ưu chi phí). A\* phải có `expanded` ≤ UCS trên đa số màn.
- DFS: lời giải hợp lệ nhưng có thể dài hơn; **không** so độ dài.

## 4. Phía GUI test khi chưa có solver

`results/sample/` chứa file kết quả viết tay. GUI đọc file này để làm hoạt ảnh Solve. Khi server Python xong thì đổi sang gọi TCP.
