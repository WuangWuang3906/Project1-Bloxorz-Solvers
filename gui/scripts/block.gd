class_name Block
extends Node3D
## The 1x1x2 block: rolls over its bottom edge, falls, sinks into the goal.
## World mapping: x = col, z = row, y = up; tile centres at integer x/z.

const ROLL_TIME := 0.24

var body: MeshInstance3D
var pos := Vector2i.ZERO
var orient: String = "STAND"


func _init() -> void:
	body = MeshInstance3D.new()
	body.mesh = MeshUtil.rounded_box(Vector3(0.96, 1.96, 0.96), 0.08)
	body.material_override = MeshUtil.mat(Color("8a5a34"), 0.32, 0.7)
	add_child(body)
	for y in [-0.6, 0.6]:
		var trim := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(0.975, 0.035, 0.975)
		trim.mesh = m
		trim.material_override = MeshUtil.glow(Color("ffb060"), 1.6)
		trim.position.y = y
		body.add_child(trim)


static func pose(p: Vector2i, o: String) -> Transform3D:
	match o:
		"STAND":
			return Transform3D(Basis.IDENTITY, Vector3(p.y, 1.0, p.x))
		"H":
			return Transform3D(Basis(Vector3.BACK, PI / 2), Vector3(p.y + 0.5, 0.5, p.x))
		_:
			return Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(p.y, 0.5, p.x + 0.5))


func set_state(p: Vector2i, o: String) -> void:
	pos = p
	orient = o
	body.transform = pose(p, o)
	body.visible = true


## Animate a roll to (new_pos, new_orient), pivoting on the bottom edge.
func roll_to(dir: String, new_pos: Vector2i, new_orient: String, duration: float = ROLL_TIME) -> void:
	var cs := OfflineRules.cells(pos, orient)
	var min_r: int = cs[0].x
	var max_r: int = cs[-1].x
	var min_c: int = cs[0].y
	var max_c: int = cs[-1].y
	var mid_r := (min_r + max_r) / 2.0
	var mid_c := (min_c + max_c) / 2.0
	var pivot := Vector3.ZERO
	var axis := Vector3.BACK
	var angle := 0.0
	match dir:
		"R":
			pivot = Vector3(max_c + 0.5, 0, mid_r)
			angle = -PI / 2
		"L":
			pivot = Vector3(min_c - 0.5, 0, mid_r)
			angle = PI / 2
		"D":
			pivot = Vector3(mid_c, 0, max_r + 0.5)
			axis = Vector3.RIGHT
			angle = PI / 2
		"U":
			pivot = Vector3(mid_c, 0, min_r - 0.5)
			axis = Vector3.RIGHT
			angle = -PI / 2
	var start := body.transform
	var tw := create_tween()
	tw.tween_method(
		func(t: float) -> void:
			var b := Basis(axis, angle * t)
			body.transform = Transform3D(b * start.basis, pivot + b * (start.origin - pivot)),
		0.0, 1.0, duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tw.finished
	set_state(new_pos, new_orient)


func fall() -> void:
	var tw := create_tween().set_parallel(true)
	tw.tween_property(body, "position:y", body.position.y - 14.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(body, "rotation:x", body.rotation.x + 1.2, 0.8)
	await tw.finished
	body.visible = false


func sink() -> void:
	var tw := create_tween()
	tw.tween_property(body, "position:y", -2.2, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	body.visible = false
