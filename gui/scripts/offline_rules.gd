class_name OfflineRules
extends RefCounted
## TEMPORARY copy of the rules (docs/GAME_RULES.md) so the GUI can be played
## before the Python server exists. Python stays the source of truth: when
## bloxorz/server.py runs, the GUI uses it instead (see net_client.gd).
##
## State dictionary: {"pos": Vector2i, "orient": "STAND"|"H"|"V"|"SPLIT",
## "open": {bridge_id: true}, "cubes": [Vector2i, Vector2i], "active": int}
## ("cubes"/"active" only when split).

const DIRS := {"U": Vector2i(-1, 0), "D": Vector2i(1, 0), "L": Vector2i(0, -1), "R": Vector2i(0, 1)}
const ROLL := {
	"STAND": {"U": [-2, 0, "V"], "D": [1, 0, "V"], "L": [0, -2, "H"], "R": [0, 1, "H"]},
	"H": {"U": [-1, 0, "H"], "D": [1, 0, "H"], "L": [0, -1, "STAND"], "R": [0, 2, "STAND"]},
	"V": {"U": [-1, 0, "STAND"], "D": [2, 0, "STAND"], "L": [0, -1, "V"], "R": [0, 1, "V"]},
}


static func roll(pos: Vector2i, orient: String, dir: String) -> Array:
	var t: Array = ROLL[orient][dir]
	return [pos + Vector2i(t[0], t[1]), t[2]]


static func cells(pos: Vector2i, orient: String) -> Array:
	match orient:
		"STAND":
			return [pos]
		"H":
			return [pos, pos + Vector2i(0, 1)]
		_:
			return [pos, pos + Vector2i(1, 0)]


static func state_cells(s: Dictionary) -> Array:
	if s["orient"] == "SPLIT":
		return s["cubes"].duplicate()
	return cells(s["pos"], s["orient"])


static func initial_state(lv: LevelData) -> Dictionary:
	var open := {}
	for id in lv.bridges:
		if lv.bridges[id]["open"]:
			open[id] = true
	return {"pos": lv.start, "orient": lv.start_orient, "open": open}


## A single cell can hold `standing` weight (whole block standing) or not.
static func cell_ok(lv: LevelData, p: Vector2i, standing: bool, open: Dictionary) -> bool:
	var t := lv.tile(p)
	if t == "-":
		return false
	if t == "B" and not open.has(lv.bridge_at.get(p, "")):
		return false
	if t == "F" and standing:
		return false
	return true


static func supported(lv: LevelData, cs: Array, standing: bool, open: Dictionary) -> bool:
	for p in cs:
		if not cell_ok(lv, p, standing, open):
			return false
	return true


## Press switches under `cs`. kind: "stand" | "lie" | "cube". Returns [open, split_to].
static func _press(lv: LevelData, cs: Array, kind: String, open_in: Dictionary, events: Array) -> Array:
	var open: Dictionary = open_in.duplicate()
	var split_to: Array = []
	for p in cs:
		if not lv.switches.has(p):
			continue
		var sw: Dictionary = lv.switches[p]
		if sw["type"] != "soft" and kind != "stand":
			continue
		for b in sw["bridges"]:
			var was_open := open.has(b)
			if sw["mode"] == "toggle":
				if was_open:
					open.erase(b)
				else:
					open[b] = true
			elif sw["mode"] == "open":
				open[b] = true
			else:
				open.erase(b)
			if open.has(b) != was_open:
				events.append("bridge:%s:%s" % [b, "open" if open.has(b) else "close"])
		if sw["type"] == "split" and not sw["split_to"].is_empty():
			split_to = [LevelData._cell(sw["split_to"][0]), LevelData._cell(sw["split_to"][1])]
	return [open, split_to]


static func _cost(lv: LevelData, s: Dictionary) -> float:
	for p in state_cells(s):
		if lv.tile(p) == "F":
			return 2.0
	return 1.0


## Returns {"state": Dictionary or null, "events": Array, "cost": float}.
static func step(lv: LevelData, s: Dictionary, action: String) -> Dictionary:
	var events: Array = []
	if s["orient"] == "SPLIT":
		return _step_split(lv, s, action, events)
	if action == "SWITCH":
		return {"state": null, "events": ["invalid"], "cost": 0.0}
	var r := roll(s["pos"], s["orient"], action)
	var pos: Vector2i = r[0]
	var orient: String = r[1]
	var cs := cells(pos, orient)
	var standing := orient == "STAND"
	if not supported(lv, cs, standing, s["open"]):
		return {"state": null, "events": ["fall"], "cost": 0.0}
	var pressed := _press(lv, cs, "stand" if standing else "lie", s["open"], events)
	var open: Dictionary = pressed[0]
	if not supported(lv, cs, standing, open):
		events.append("fall")
		return {"state": null, "events": events, "cost": 0.0}
	var next := {"pos": pos, "orient": orient, "open": open}
	if not pressed[1].is_empty():
		events.append("split")
		next = {"pos": pressed[1][0], "orient": "SPLIT", "open": open, "cubes": pressed[1], "active": 0}
	if is_goal(lv, next):
		events.append("win")
	return {"state": next, "events": events, "cost": _cost(lv, next)}


static func _step_split(lv: LevelData, s: Dictionary, action: String, events: Array) -> Dictionary:
	var cubes: Array = s["cubes"].duplicate()
	var a: int = s["active"]
	if action == "SWITCH":
		var sw := s.duplicate()
		sw["active"] = 1 - a
		return {"state": sw, "events": ["switch"], "cost": 1.0}
	var n: Vector2i = cubes[a] + DIRS[action]
	if n == cubes[1 - a] or not cell_ok(lv, n, false, s["open"]):
		return {"state": null, "events": ["fall"], "cost": 0.0}
	var pressed := _press(lv, [n], "cube", s["open"], events)
	var open: Dictionary = pressed[0]
	cubes[a] = n
	if not supported(lv, cubes, false, open):
		events.append("fall")
		return {"state": null, "events": events, "cost": 0.0}
	var c0: Vector2i = cubes[0]
	var c1: Vector2i = cubes[1]
	var next: Dictionary
	if absi(c0.x - c1.x) + absi(c0.y - c1.y) == 1:
		events.append("merge")
		var anchor := Vector2i(mini(c0.x, c1.x), mini(c0.y, c1.y))
		next = {"pos": anchor, "orient": "H" if c0.x == c1.x else "V", "open": open}
	else:
		next = {"pos": cubes[0], "orient": "SPLIT", "open": open, "cubes": cubes, "active": a}
	return {"state": next, "events": events, "cost": _cost(lv, next)}


static func is_goal(lv: LevelData, s: Dictionary) -> bool:
	return s["orient"] == "STAND" and s["pos"] == lv.goal
