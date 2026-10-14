class_name OfflineRules
extends RefCounted
## TEMPORARY copy of the basic rules (docs/GAME_RULES.md) so the GUI can be
## played before the Python server exists. Python stays the source of truth;
## once bloxorz/server.py works the GUI must ask the server instead.
## Not supported here: split switches / split cubes.

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


static func initial_state(lv: LevelData) -> Dictionary:
	var open := {}
	for id in lv.bridges:
		if lv.bridges[id]["open"]:
			open[id] = true
	return {"pos": lv.start, "orient": lv.start_orient, "open": open}


static func supported(lv: LevelData, cs: Array, standing: bool, open: Dictionary) -> bool:
	for p in cs:
		var t := lv.tile(p)
		if t == "-":
			return false
		if t == "B" and not open.has(lv.bridge_at.get(p, "")):
			return false
		if t == "F" and standing:
			return false
	return true


## Returns {"state": Dictionary or null, "pos", "orient", "events": Array}.
static func step(lv: LevelData, state: Dictionary, dir: String) -> Dictionary:
	var r := roll(state["pos"], state["orient"], dir)
	var pos: Vector2i = r[0]
	var orient: String = r[1]
	var cs := cells(pos, orient)
	var standing := orient == "STAND"
	var events: Array = []
	if not supported(lv, cs, standing, state["open"]):
		return {"state": null, "pos": pos, "orient": orient, "events": ["fall"]}
	var open: Dictionary = state["open"].duplicate()
	for p in cs:
		if not lv.switches.has(p):
			continue
		var sw: Dictionary = lv.switches[p]
		if sw["type"] != "soft" and not standing:
			continue
		if sw["type"] == "split":
			events.append("split_unsupported")
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
	if not supported(lv, cs, standing, open):
		events.append("fall")
		return {"state": null, "pos": pos, "orient": orient, "events": events}
	var next := {"pos": pos, "orient": orient, "open": open}
	if is_goal(lv, next):
		events.append("win")
	return {"state": next, "pos": pos, "orient": orient, "events": events}


static func is_goal(lv: LevelData, state: Dictionary) -> bool:
	return state["orient"] == "STAND" and state["pos"] == lv.goal
