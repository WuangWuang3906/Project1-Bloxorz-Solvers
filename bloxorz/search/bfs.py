"""Tìm kiếm theo chiều rộng (Breadth-First Search — BFS). Tác giả: Tú (TV2).

BFS duyệt các trạng thái theo từng mức: trước hết là các trạng thái có thể đến
sau 1 hành động, tiếp theo là 2 hành động, 3 hành động, v.v. Vì vậy, lời giải
đầu tiên tìm được sẽ sử dụng ít hành động nhất.

Thuật toán:
  - Biên tìm kiếm (frontier): hàng đợi FIFO (collections.deque).
  - Tập đã thăm (visited): lưu các trạng thái đã gặp để không xử lý lặp lại.
  - Bảng cha (parent): ánh xạ mỗi trạng thái tới (trạng thái trước, hành động)
    để dựng lại đường đi khi tìm thấy đích.
  - Kiểm tra đích sớm: gọi is_goal ngay khi trạng thái con được sinh ra và thêm
    vào hàng đợi, thay vì chờ đến lúc lấy nó ra để mở rộng. Cách này đúng với
    BFS vì mọi trạng thái ở độ sâu d được sinh trước các trạng thái ở độ sâu
    d + 1, nên đích đầu tiên tìm thấy có số hành động tối thiểu.

Tính đầy đủ: Có — BFS đầy đủ với không gian trạng thái hữu hạn. Bàn Bloxorz là
    hữu hạn nên số trạng thái có thể đạt tới cũng bị giới hạn.
Tính tối ưu: Có — BFS tìm lời giải có số hành động ít nhất vì mỗi hành động
    được tính là một bước. Lưu ý: BFS không tối ưu theo hàm chi phí có trọng số
    trong GAME_RULES (ô dễ vỡ có chi phí 2). Muốn tối ưu chi phí, dùng UCS hoặc A*.
Độ phức tạp thời gian: O(V + E), với V là số trạng thái có thể đạt tới và E là
    số phép chuyển trạng thái. Trong trường hợp xấu nhất là O(b^d), với b là hệ
    số phân nhánh (khoảng 5 nếu tính cả SWITCH) và d là độ sâu lời giải.
Độ phức tạp không gian: O(V) cho tập visited và bảng parent; trong trường hợp
    xấu nhất phải lưu tất cả trạng thái có thể đạt tới.
"""
from __future__ import annotations

from collections import deque

from bloxorz.core.level import Level
from bloxorz.core.rules import is_goal, successors
from bloxorz.core.state import State
from bloxorz.search.common import SearchResult, reconstruct


def bfs(level: Level, start: State) -> SearchResult:
    """Tìm lời giải có ít hành động nhất bằng tìm kiếm theo chiều rộng.

    Tham số:
        level: Màn chơi đã tải, gồm bàn cờ, công tắc, cầu và ô đích.
        start: Trạng thái ban đầu, gồm vị trí, hướng và các cầu đang mở.

    Trả về:
        SearchResult có found=True và danh sách hành động nếu tồn tại lời giải;
        ngược lại, found=False và danh sách hành động rỗng.
    """
    # --- Kiểm tra sớm xem trạng thái ban đầu đã là đích hay chưa ---
    if is_goal(level, start):
        return SearchResult(found=True, actions=[], cost=0.0, expanded=0)

    # --- Các cấu trúc dữ liệu ---
    # frontier: hàng đợi FIFO chứa các trạng thái sẽ được mở rộng tiếp theo
    frontier: deque[State] = deque()
    frontier.append(start)

    # visited: tập trạng thái đã gặp, được kiểm tra ngay khi sinh trạng thái con
    visited: set[State] = {start}

    # parent: ánh xạ trạng thái tới (trạng thái trước, hành động đã thực hiện)
    # reconstruct() dùng bảng này để dựng lại chuỗi hành động khi tìm thấy đích.
    parent: dict[State, tuple[State, str] | None] = {start: None}

    # cost_so_far: tổng chi phí có trọng số từ trạng thái đầu tới mỗi trạng thái
    cost_so_far: dict[State, float] = {start: 0.0}

    expanded = 0  # số nút đã được lấy khỏi frontier để mở rộng

    # --- Vòng lặp chính của BFS ---
    while frontier:
        current = frontier.popleft()
        expanded += 1  # current vừa được lấy khỏi frontier để mở rộng

        # Sinh tất cả trạng thái kế tiếp hợp lệ
        for action, child, step_cost in successors(level, current):
            if child in visited:
                continue  # bỏ qua trạng thái đã gặp

            # Ghi nhận trạng thái con vừa sinh
            visited.add(child)
            parent[child] = (current, action)
            cost_so_far[child] = cost_so_far[current] + step_cost

            # Kiểm tra đích ngay khi trạng thái con được sinh ra
            if is_goal(level, child):
                actions = reconstruct(parent, child)
                return SearchResult(
                    found=True,
                    actions=actions,
                    cost=cost_so_far[child],
                    expanded=expanded,
                )

            frontier.append(child)

    # Đã duyệt hết các trạng thái có thể đạt tới nhưng không tìm thấy đích
    return SearchResult(found=False, actions=[], cost=0.0, expanded=expanded)
