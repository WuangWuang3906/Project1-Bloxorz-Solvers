class_name Board
extends Node3D
## Builds the 3D tiles of a level and animates bridges.

const TILE_H := 0.34

## "ring" (glowing ring + light) | "plain" (just the hole) — set before build().
static var goal_style: String = "ring"
## Switch markers: "dam" (strong, saturated colours) | "nhat" (soft glow).
## Changed from the settings board; apply with set_marker_style().
static var marker_style: String = "dam"

const MARKER_COLORS := {
	"dam": {"soft": Color("00a3cc"), "heavy": Color("e8195f"), "split": Color("9b45f0")},   # same hues, deeper
	"nhat": {"soft": Color("8fe8ff"), "heavy": Color("ff5070"), "split": Color("c080ff")},
}

var bridge_nodes: Dictionary = {}   # bridge id -> Array[Node3D]
var _markers: Array = []            # [MeshInstance3D, kind] of every switch marker

var _tile_mesh: ArrayMesh = MeshUtil.rounded_box(Vector3(0.96, TILE_H, 0.96), 0.07)
var _floor_a := Foliage.stone_material(Color(1.0, 0.98, 0.94))    # old mottled stone
var _floor_b := Foliage.stone_material(Color(0.93, 0.91, 0.86))
var _fragile := MeshUtil.mat(Color("ff7a1a"), 0.22)
var _bridge := MeshUtil.mat(Color("6d7488"), 0.28, 0.9)
var _hole := MeshUtil.mat(Color("050208"), 1.0)


func build(lv: LevelData) -> void:
	for child in get_children():
		child.queue_free()
	bridge_nodes.clear()
	_markers.clear()
	for r in lv.rows:
		for c in lv.cols:
			var cell := Vector2i(r, c)
			var ch := lv.tile(cell)
			match ch:
				"-":
					pass
				"G":
					_add_goal(cell)
				"B":
					var bid: String = lv.bridge_at.get(cell, "")
					var node := _add_tile(cell, _bridge)
					_add_bridge_strips(node)
					if not bridge_nodes.has(bid):
						bridge_nodes[bid] = []
					bridge_nodes[bid].append(node)
				"F":
					_add_tile(cell, _fragile)
				_:
					var node := _add_tile(cell, _floor_a if (r + c) % 2 == 0 else _floor_b)
					match ch:
						"o":
							_add_soft_switch(node)
						"X":
							_add_heavy_switch(node)
						"P":
							_add_split_switch(node)


func _add_tile(cell: Vector2i, material: Material) -> Node3D:
	var root := Node3D.new()
	root.position = Vector3(cell.y, 0, cell.x)
	add_child(root)
	var mi := MeshInstance3D.new()
	mi.mesh = _tile_mesh
	mi.material_override = material
	mi.position.y = -TILE_H / 2
	root.add_child(mi)
	return root


func _add_goal(cell: Vector2i) -> void:
	var root := Node3D.new()
	root.position = Vector3(cell.y, 0, cell.x)
	add_child(root)
	var hole := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.42
	cyl.bottom_radius = 0.42
	cyl.height = TILE_H
	hole.mesh = cyl
	hole.material_override = _hole
	hole.position.y = -TILE_H / 2
	root.add_child(hole)
	if goal_style == "plain":
		return
	var ring := MeshInstance3D.new()
	var torus := TorusMesh.new()
	torus.inner_radius = 0.40
	torus.outer_radius = 0.48
	ring.mesh = torus
	ring.material_override = MeshUtil.glow(Color("ffc060"), 3.0)
	ring.scale = Vector3(1, 0.4, 1)
	root.add_child(ring)
	var light := OmniLight3D.new()
	light.light_color = Color("ffa040")
	light.light_energy = 1.2
	light.omni_range = 2.2
	light.position.y = 0.5
	root.add_child(light)


func _add_bridge_strips(node: Node3D) -> void:
	for dz in [-0.3, 0.3]:
		var s := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(0.8, 0.02, 0.04)
		s.mesh = m
		s.material_override = MeshUtil.glow(Color("5ad0ff"), 2.0)
		s.position = Vector3(0, 0.005, dz)
		node.add_child(s)


func _add_soft_switch(node: Node3D) -> void:
	var s := MeshInstance3D.new()
	var m := CylinderMesh.new()
	m.top_radius = 0.28
	m.bottom_radius = 0.31
	m.height = 0.06
	s.mesh = m
	_set_marker(s, "soft")
	s.position.y = 0.03
	node.add_child(s)


func _add_heavy_switch(node: Node3D) -> void:
	for k in [1, -1]:
		var s := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(0.66, 0.07, 0.16)
		s.mesh = m
		_set_marker(s, "heavy")
		s.position.y = 0.03
		s.rotation.y = k * PI / 4
		node.add_child(s)


func _add_split_switch(node: Node3D) -> void:
	for dx in [-0.18, 0.18]:
		var s := MeshInstance3D.new()
		var m := BoxMesh.new()
		m.size = Vector3(0.07, 0.06, 0.5)
		s.mesh = m
		_set_marker(s, "split")
		s.position = Vector3(dx, 0.03, 0)
		node.add_child(s)


func _set_marker(mi: MeshInstance3D, kind: String) -> void:
	_markers.append([mi, kind])
	mi.material_override = _marker_material(kind)


static func _marker_material(kind: String) -> StandardMaterial3D:
	var c: Color = MARKER_COLORS[marker_style][kind]
	if marker_style == "dam":
		var m := MeshUtil.mat(c, 0.35)   # solid colour, a little glow so it stays readable
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 0.25
		return m
	return MeshUtil.glow(c, 1.5)


## Re-colour every switch marker of the current board (settings changed).
func set_marker_style(style: String) -> void:
	marker_style = style
	for pair in _markers:
		(pair[0] as MeshInstance3D).material_override = _marker_material(pair[1])


## Show open bridges, hide closed ones. Animated: closed tiles flip down and
## sink away; opening tiles swing back up one after another.
func set_bridges(open: Dictionary, animate: bool = true) -> void:
	for bid in bridge_nodes:
		var is_open := open.has(bid)
		var nodes: Array = bridge_nodes[bid]
		for i in nodes.size():
			var node: Node3D = nodes[i]
			var was_open := node.visible
			if not animate or was_open == is_open:
				node.visible = is_open
				node.position.y = 0.0
				node.rotation.x = 0.0
				continue
			var tw: Tween = node.create_tween()
			tw.tween_interval(i * 0.07)
			if is_open:
				node.visible = true
				node.position.y = -1.4
				node.rotation.x = -PI / 2
				tw.tween_property(node, "position:y", 0.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				tw.parallel().tween_property(node, "rotation:x", 0.0, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			else:
				tw.tween_property(node, "rotation:x", PI / 2, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				tw.parallel().tween_property(node, "position:y", -1.4, 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				tw.tween_callback(func() -> void: node.visible = false)
