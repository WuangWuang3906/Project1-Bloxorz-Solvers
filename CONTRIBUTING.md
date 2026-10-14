# Quy trình làm việc nhóm

## Nhánh

- `main`: luôn chạy được. **Không push thẳng vào `main`.**
- Mỗi việc một nhánh: `feat/<vai>-<việc>`, ví dụ `feat/core-roll`, `feat/bfs`, `feat/gui-board`, `fix/fragile-cost`.

## Mỗi ngày làm việc

```bash
git checkout main
git pull
git checkout -b feat/bfs          # lần đầu; lần sau: git checkout feat/bfs && git merge main
# ... code ...
pytest -q                          # ít nhất các test thuộc phần mình phải pass
git add <file>
git commit -m "bfs: add visited set and path reconstruction"
git push -u origin feat/bfs
```

Sau đó mở **Pull Request** vào `main` trên GitHub. Cần **1 người khác duyệt** rồi mới merge.

## Commit message

`<phần>: <làm gì>` bằng tiếng Anh, thì hiện tại, ngắn. Phần: `core`, `bfs`, `dfs`, `ucs`, `astar`, `server`, `bench`, `levels`, `gui`, `tests`, `docs`.

## Checklist trước khi mở PR

- [ ] `pytest -q` không làm hỏng test đang pass.
- [ ] Không sửa file của vai khác (xem bảng trong `AGENTS.md`), trừ khi đã báo.
- [ ] Không đổi luật / định dạng JSON / API khi chưa cập nhật `docs/` và báo nhóm.
- [ ] Không commit `__pycache__`, `.venv`, `.godot/`, `results/*.csv` lớn.
- [ ] Nếu dùng AI: ghi prompt chính vào `docs/AI_USAGE.md`.

## Xung đột (conflict)

Gặp conflict khi merge `main` vào nhánh mình: sửa trên máy, chạy lại `pytest`, rồi commit. Không chắc thì hỏi người sở hữu file đó.
