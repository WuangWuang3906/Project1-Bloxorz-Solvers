# Luật game đã chốt (v1 — 2026-10-14)

Nguồn: đề `AI - Project 1.pdf` mục 2 (tr. 2–3) và FAQ lớp. Những điểm đề không nói rõ được nhóm **tự chốt** (đánh dấu ⚙). Muốn đổi luật: sửa file này trước và báo cả nhóm.

## 1. Bàn cờ

| Ký tự | Ô | Chịu được |
| --- | --- | --- |
| `-` | void | không gì cả |
| `#` | floor | mọi thứ |
| `S` | floor (ô xuất phát) | mọi thứ |
| `F` | fragile | khối **nằm** hoặc cube đơn ⚙; khối **đứng** thì rơi |
| `G` | goal | khối đứng → **thắng**; khối nằm/cube đơn: như floor |
| `B` | bridge | như floor khi **mở**, như void khi **đóng** |
| `o` `X` `P` | soft / heavy / split switch | như floor |

Đi ra ngoài lưới = rơi.

## 2. Tư thế và bảng lăn

Tọa độ `(r, c)`, `r` tăng xuống dưới. Ô neo của khối nằm là ô trên/trái.

| Tư thế | Chiếm ô |
| --- | --- |
| `STAND` | `(r,c)` |
| `H` | `(r,c)`, `(r,c+1)` |
| `V` | `(r,c)`, `(r+1,c)` |

| Từ \ Hướng | `U` | `D` | `L` | `R` |
| --- | --- | --- | --- | --- |
| `STAND (r,c)` | `V (r-2,c)` | `V (r+1,c)` | `H (r,c-2)` | `H (r,c+1)` |
| `H (r,c)` | `H (r-1,c)` | `H (r+1,c)` | `STAND (r,c-1)` | `STAND (r,c+2)` |
| `V (r,c)` | `STAND (r-1,c)` | `STAND (r+2,c)` | `V (r,c-1)` | `V (r,c+1)` |

Bảng này có unit test đầy đủ trong `tests/test_roll.py`.

## 3. Thứ tự xử lý một nước ⚙

1. Tính vị trí/tư thế mới theo bảng lăn.
2. **Kiểm tra hỗ trợ** (void, ngoài lưới, cầu đóng, đứng trên fragile). Không đạt thì nước đi **không hợp lệ** (khối rơi).
3. **Kích hoạt switch** dưới các ô khối đang chiếm (mục 4).
4. **Kiểm tra hỗ trợ lại**: nếu cầu vừa đóng ngay dưới khối thì khối rơi, nước đi không hợp lệ.
5. Nếu đang tách: hai cube kề nhau (4 hướng) thì **tự nhập** (mục 5).
6. Kiểm tra thắng: khối nguyên `STAND` trên `G`.

Trong solver, nước đi không hợp lệ đơn giản là **không sinh ra trạng thái con**.

## 4. Switch ⚙

- Kích hoạt **mỗi khi một nước đi kết thúc** với khối đè lên switch. Không có nước "đứng yên".
- `soft` (`o`): bất kỳ phần nào của khối hoặc cube đơn đè lên.
- `heavy` (`X`): chỉ khi khối nguyên **đứng** trên nó.
- `split` (`P`): chỉ khi khối nguyên **đứng** trên nó → tách (mục 5).
- `mode`: `toggle` đảo trạng thái mỗi cầu liên kết; `open`/`close` đặt cố định (permanent).
- Khối nằm đè **cả hai ô đều là switch**: kích hoạt cả hai, theo thứ tự ô neo trước.

## 5. Tách và nhập khối ⚙

- Split switch dịch chuyển khối thành hai cube tại `split_to[0]` và `split_to[1]`. Cube 0 được điều khiển trước.
- Mỗi nước chỉ cube đang điều khiển di chuyển **1 ô**. Action `SWITCH` đổi cube điều khiển.
- Cube đơn: đứng được trên floor, fragile, goal, cầu mở. Chỉ kích hoạt **soft** switch. Không thể thắng.
- Hai cube không được chồng lên nhau (nước đi vào ô của cube kia là không hợp lệ).
- Sau nước đi, nếu hai cube kề nhau thì nhập thành `H` (cùng hàng) hoặc `V` (cùng cột), neo ở ô trên/trái.

## 6. Hàm chi phí (UCS, A\*) ⚙

| Action | Chi phí |
| --- | --- |
| Lăn khối / di chuyển cube | 1 |
| …mà khi kết thúc khối có ô nằm trên fragile | 2 (rủi ro) |
| `SWITCH` | 1 |

Mọi chi phí ≥ 1, nên mọi heuristic đếm cận dưới số nước (ví dụ Manhattan/2) vẫn **admissible** theo hàm chi phí này. BFS và IDS tối ưu theo **số action**, không phải theo chi phí.

## 7. Độ dài lời giải

`length` = số action, tính cả `SWITCH`.
