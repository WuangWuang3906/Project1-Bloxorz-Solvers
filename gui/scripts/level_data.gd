class_name LevelData
extends RefCounted
## Level JSON (docs/JSON_FORMAT.md). Cells are Vector2i(row, col).

var id: int = 0
var level_name: String = ""
var group: String = ""
var grid: Array = []
var rows: int = 0
var cols: int = 0
var start := Vector2i.ZERO
var start_orient: String = "STAND"
var goal := Vector2i.ZERO
var bridges: Dictionary = {}     # id -> {"cells": Array[Vector2i], "open": bool}
var bridge_at: Dictionary = {}   # Vector2i -> bridge id
var switches: Dictionary = {}    # Vector2i -> {"id","type","mode","bridges","split_to"}


static func load_file(path: String) -> LevelData:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		push_error("Cannot open level: %s" % path)
		return null
	var data: Variant = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		push_error("Invalid level JSON: %s" % path)
		return null
	var lv := LevelData.new()
	lv.id = int(data.get("id", 0))
	lv.level_name = str(data.get("name", ""))
	lv.group = str(data.get("group", ""))
	lv.grid = data["grid"]
	lv.rows = lv.grid.size()
	lv.cols = str(lv.grid[0]).length()
	lv.start = _cell(data["start"]["pos"])
	lv.start_orient = str(data["start"].get("orient", "STAND"))
	for r in lv.rows:
		var c: int = str(lv.grid[r]).find("G")
		if c >= 0:
			lv.goal = Vector2i(r, c)
	for b in data.get("bridges", []):
		var cells: Array = []
		for p in b["cells"]:
			cells.append(_cell(p))
			lv.bridge_at[_cell(p)] = str(b["id"])
		lv.bridges[str(b["id"])] = {"cells": cells, "open": bool(b["open"])}
	for s in data.get("switches", []):
		var sw := {
			"id": str(s["id"]), "type": str(s["type"]), "mode": str(s.get("mode", "toggle")),
			"bridges": s.get("bridges", []), "split_to": s.get("split_to", []),
		}
		lv.switches[_cell(s["pos"])] = sw
	return lv


static func _cell(p: Variant) -> Vector2i:
	return Vector2i(int(p[0]), int(p[1]))


## Tile char at a cell; outside the grid counts as void.
func tile(p: Vector2i) -> String:
	if p.x < 0 or p.y < 0 or p.x >= rows or p.y >= cols:
		return "-"
	return str(grid[p.x])[p.y]
