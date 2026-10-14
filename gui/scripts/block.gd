class_name Block
extends Node3D
## The 1x1x2 block and the two unit cubes after a split (look: BlockSkin).
## World mapping: x = col, z = row, y = up; tile centres at integer x/z.

const ROLL_TIME := 0.24
const DIR_VEC := {"U": Vector3(0, 0, -1), "D": Vector3(0, 0, 1), "L": Vector3(-1, 0, 0), "R": Vector3(1, 0, 0)}

var body: MeshInstance3D
var cubes: Array = []          # two MeshInstance3D
var active_marker: MeshInstance3D
var pos := Vector2i.ZERO
var orient: String = "STAND"
var cube_cells: Array = []
var active: int = 0


func _init() -> void:
	body = MeshInstance3D.new()
	body.mesh = MeshUtil.rounded_box(Vector3(0.96, 1.96, 0.96), 0.03)
	BlockSkin.dress_block(body)
	add_child(body)

	var cube_mesh := MeshUtil.rounded_box(Vector3(0.96, 0.96, 0.96), 0.03)
	for i in 2:
		var c := MeshInstance3D.new()
		c.mesh = cube_mesh
		BlockSkin.dress_cube(c)
		c.visible = false
		add_child(c)
		cubes.append(c)

	active_marker = MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.5
	ring.outer_radius = 0.56
	active_marker.mesh = ring
	active_marker.material_override = MeshUtil.glow(Color("7fe0ff"), 3.0)
	active_marker.scale = Vector3(1, 0.3, 1)
	active_marker.visible = false
	add_child(active_marker)


# ---- poses -------------------------------------------------------------

static func pose(p: Vector2i, o: String) -> Transform3D:
	match o:
		"STAND":
			return Transform3D(Basis.IDENTITY, Vector3(p.y, 1.0, p.x))
		"H":
			return Transform3D(Basis(Vector3.BACK, PI / 2), Vector3(p.y + 0.5, 0.5, p.x))
		_:
			return Transform3D(Basis(Vector3.RIGHT, PI / 2), Vector3(p.y, 0.5, p.x + 0.5))


static func cube_pose(c: Vector2i) -> Transform3D:
	return Transform3D(Basis.IDENTITY, Vector3(c.y, 0.5, c.x))


## Show state `s`. Normally resets to the canonical pose; with keep_rotation the
## cubes keep how they are currently turned (only their positions are set).
func set_state(s: Dictionary, keep_rotation: bool = false) -> void:
	orient = s["orient"]
	pos = s["pos"]
	var split := orient == "SPLIT"
	body.visible = not split
	for c in cubes:
		c.visible = split
		c.scale = Vector3.ONE
	active_marker.visible = split
	if split:
		cube_cells = s["cubes"].duplicate()
		active = s["active"]
		for i in 2:
			var basis: Basis = _snap(cubes[i].basis) if keep_rotation else Basis.IDENTITY
			cubes[i].transform = Transform3D(basis, cube_pose(cube_cells[i]).origin)
		_place_marker()
	else:
		body.transform = pose(pos, orient)
		body.scale = Vector3.ONE


func _place_marker() -> void:
	var c: Vector2i = cube_cells[active]
	active_marker.position = Vector3(c.y, 0.02, c.x)


# ---- animations --------------------------------------------------------

func _rotate_about(node: Node3D, pivot: Vector3, axis: Vector3, angle: float, duration: float,
		ease_type: Tween.EaseType = Tween.EASE_IN_OUT) -> void:
	var start := node.transform
	var tw := create_tween()
	tw.tween_method(
		func(t: float) -> void:
			var b := Basis(axis, angle * t)
			node.transform = Transform3D(b * start.basis, pivot + b * (start.origin - pivot)),
		0.0, 1.0, duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(ease_type)
	await tw.finished


static func _edge(cs: Array, dir: String) -> Vector3:
	## Bottom edge of the footprint `cs` on the side of `dir`.
	var min_r: int = cs[0].x
	var max_r: int = cs[-1].x
	var min_c: int = cs[0].y
	var max_c: int = cs[-1].y
	var mid_r := (min_r + max_r) / 2.0
	var mid_c := (min_c + max_c) / 2.0
	match dir:
		"R":
			return Vector3(max_c + 0.5, 0, mid_r)
		"L":
			return Vector3(min_c - 0.5, 0, mid_r)
		"D":
			return Vector3(mid_c, 0, max_r + 0.5)
		_:
			return Vector3(mid_c, 0, min_r - 0.5)


## Roll the whole block over its bottom edge (pose updated, no state change).
func roll_to(dir: String, new_pos: Vector2i, new_orient: String) -> void:
	var v: Vector3 = DIR_VEC[dir]
	await _rotate_about(body, _edge(OfflineRules.cells(pos, orient), dir), Vector3.UP.cross(v), PI / 2, ROLL_TIME)
	pos = new_pos
	orient = new_orient
	# Keep the real rotation (the face/cap must follow the roll); only snap
	# floating-point drift and put the centre exactly on the cells.
	body.transform = Transform3D(_snap(body.basis), pose(pos, orient).origin)


## Roll the active cube one cell.
func cube_roll(dir: String) -> void:
	var c: Vector2i = cube_cells[active]
	var v: Vector3 = DIR_VEC[dir]
	active_marker.visible = false
	await _rotate_about(cubes[active], _edge([c], dir), Vector3.UP.cross(v), PI / 2, ROLL_TIME * 0.8)
	cube_cells[active] = c + OfflineRules.DIRS[dir]
	cubes[active].transform = Transform3D(_snap(cubes[active].basis), cube_pose(cube_cells[active]).origin)


## Round a rotation made of 90° turns back to exact -1/0/1 entries.
static func _snap(b: Basis) -> Basis:
	return Basis(b.x.round(), b.y.round(), b.z.round())


## The block just landed on `cs` and some cells are unsupported: tip over the
## supporting edge (if any) and tumble down.
func tumble(node: Node3D, cs: Array, ok: Array, dir: String) -> void:
	var sup: Array = []
	var uns: Array = []
	for i in cs.size():
		var p := Vector3(cs[i].y, 0, cs[i].x)
		if ok[i]:
			sup.append(p)
		else:
			uns.append(p)
	var tip: Vector3 = DIR_VEC[dir]
	if not sup.is_empty() and not uns.is_empty():
		var cs_c := _centroid(sup)
		var cu_c := _centroid(uns)
		tip = (cu_c - cs_c).normalized()
		await _rotate_about(node, (cs_c + cu_c) / 2.0, Vector3.UP.cross(tip), PI / 2, 0.28, Tween.EASE_IN)
	var start := node.transform
	var axis := Vector3.UP.cross(tip)
	var tw := create_tween()
	tw.tween_method(
		func(t: float) -> void:
			var b := Basis(axis, t * t * 2.5 * PI)
			node.transform = Transform3D(b * start.basis, start.origin + tip * (t * 1.4) + Vector3.DOWN * (t * t * 14.0)),
		0.0, 1.0, 1.0
	)
	await tw.finished
	node.visible = false


static func _centroid(points: Array) -> Vector3:
	var s := Vector3.ZERO
	for p in points:
		s += p
	return s / points.size()


## Split switch: the block shrinks away and two cubes pop up at their targets.
func split_into(s: Dictionary) -> void:
	var tw := create_tween()
	tw.tween_property(body, "scale", Vector3(0.05, 0.05, 0.05), 0.18)
	await tw.finished
	set_state(s)
	var tw2 := create_tween().set_parallel(true)
	for c in cubes:
		c.scale = Vector3(0.05, 0.05, 0.05)
		tw2.tween_property(c, "scale", Vector3.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw2.finished


func set_active(i: int) -> void:
	active = i
	_place_marker()
	active_marker.visible = true
	var c: MeshInstance3D = cubes[i]
	var tw := create_tween()
	tw.tween_property(c, "position:y", 0.8, 0.12).set_ease(Tween.EASE_OUT)
	tw.tween_property(c, "position:y", 0.5, 0.18).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)


## Win: a little hop, then the block sinks into the hole.
func sink() -> void:
	var tw := create_tween()
	tw.tween_property(body, "position:y", body.position.y + 0.35, 0.18).set_ease(Tween.EASE_OUT)
	tw.tween_property(body, "position:y", -2.2, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	body.visible = false
