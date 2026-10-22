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

### Vì sao trọng số ô dễ vỡ là 2 (FAQ lớp, câu 10: trọng số phải có lý do)

**Ý nghĩa:** khối nằm trên ô dễ vỡ là trạng thái rủi ro: chỉ một nước dựng đứng sai là vỡ ô và thua. Chi phí phạt mức rủi ro đó, nên UCS/A\* ưu tiên đường an toàn khi đường an toàn không quá dài.

**Thí nghiệm** (`python benchmark/cost_weights.py`, chạy UCS với trọng số w = 1; 1,5; 2; 3; 5; 10, luật khác giữ nguyên). Mỗi ô: *độ dài lời giải / số nước kết thúc trên ô dễ vỡ*.

| Màn | w = 1 | w = 1,5 | **w = 2** | w = 3 | w = 5 | w = 10 |
| --- | --- | --- | --- | --- | --- | --- |
| 04 Thin ice | 17 / 4 | 17 / 4 | **17 / 4** | 17 / 4 | 17 / 4 | 17 / 4 |
| 05 Fragile maze | 16 / 7 | 16 / 7 | **16 / 7** | 16 / 7 | 16 / 7 | 22 / 6 |
| 06 Safe detour | 21 / 14 | 21 / 14 | **26 / 4** | 26 / 4 | 26 / 4 | 26 / 4 |
| 12 Grand finale | 33 / 2 | 33 / 2 | **33 / 2** | 34 / 1 | 34 / 1 | 34 / 1 |
| 13, 15 (màn lớn) | lời giải không đi qua ô dễ vỡ ở mọi w; chỉ số nút duyệt thay đổi | | | | | |

**Đọc kết quả:**

- w = 1 chính là BFS (ít nước nhất): màn 06 đi thẳng qua 14 nước trên ô dễ vỡ.
- Màn 06 có hai đường: đi thẳng (21 nước, 14 nước trên ô dễ vỡ, chi phí 7 + 14w) và đi vòng (26 nước, 4 nước trên ô dễ vỡ, chi phí 22 + 4w). Hai đường **bằng nhau khi w = 1,5**; từ **w = 2** UCS chọn hẳn đường vòng: thêm 5 nước để bớt 10 nước rủi ro.
- w = 3 bắt đầu "đắt" hơn cần thiết: màn 12 thêm 1 nước chỉ để bớt 1 nước trên ô dễ vỡ. w = 10 quá thận trọng: màn 05 dài thêm 6 nước (16 → 22, +37%) để bớt 1 nước rủi ro.
- Màn 04, 05 bắt buộc phải đi qua ô dễ vỡ, nên trọng số chỉ đổi chi phí, không đổi đường đi ở mức vừa phải.

**Kết luận:** w = 2 là **số nguyên nhỏ nhất** làm UCS tránh vùng rủi ro khi có đường vòng ngắn (màn 06), mà **không làm dài** lời giải ở các màn khác (04, 05, 12 giữ nguyên đường ngắn nhất). Lưu ý trung thực: màn 06 do nhóm thiết kế để minh hoạ UCS khác BFS, nên ngưỡng 1,5 phụ thuộc màn đó; xu hướng chung (w càng lớn càng né ô dễ vỡ và đường càng dài) thấy ở cả 05 và 12.

## 7. Độ dài lời giải

`length` = số action, tính cả `SWITCH`.
