class_name KeyHints
extends Node3D
## Four triangles floating in a ring above the block's head (or the active
## cube), pointing where each arrow key rolls it. The red one is the ↑ key,
## which always rolls the block "into" the screen; the others are yellow.

const COLOR := Color("ffd23f")
const UP_COLOR := Color("e8432e")
const YAW := {"U": 0.0, "D": PI, "L": PI / 2.0, "R": -PI / 2.0}

var _hints: Dictionary = {}   # action -> Node3D (pivot at the block edge)
var _arrows: Dictionary = {}  # action -> MeshInstance3D (moves along the pivot's -Z)
var _mats: Array = []
var _shown: Dictionary = {}
var _t: float = 0.0
## Board move done by the ↑ key right now (main.gd sets it); drawn red.
var up_action: String = "U"


func _ready() -> void:
	for action in YAW:
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = COLOR
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.no_depth_test = true    # floats above the block, always readable
		mat.render_priority = 1
		_mats.append(mat)
		var pivot := Node3D.new()
		add_child(pivot)
		var arrow := MeshInstance3D.new()          # flat triangle pointing along -Z
		var tri := PrismMesh.new()
		tri.size = Vector3(0.46, 0.38, 0.02)
		arrow.mesh = tri
		arrow.material_override = mat
		arrow.rotation_degrees = Vector3(-90, 0, 0)
		pivot.add_child(arrow)
		_hints[action] = pivot
		_arrows[action] = arrow
	visible = false


func _process(delta: float) -> void:
	if not visible:
		return
	_t += delta
	var k := fmod(_t * 0.9, 1.0)                      # 0 -> 1 every ~1.1 s
	var slide := 0.05 + 0.22 * k                      # glide outward from the ring
	var alpha := sin(k * PI)                          # fade in, then out
	for action in _arrows:
		var a: MeshInstance3D = _arrows[action]
		a.position = Vector3(0, 0.06 * sin(_t * 3.0), -slide)   # bob and glide
	var keys := YAW.keys()
	for i in _mats.size():
		var c: Color = UP_COLOR if keys[i] == up_action else COLOR
		c.a = 0.6 + 0.4 * alpha
		(_mats[i] as StandardMaterial3D).albedo_color = c


## Place the hints around `state` (GUI state dictionary); hide with null.
func show_for(state: Variant) -> void:
	if state == null:
		visible = false
		_shown = {}
		return
	if visible and state == _shown:
		return
	_shown = state
	var cells: Array
	if state["orient"] == "SPLIT":
		cells = [state["cubes"][state["active"]]]
	else:
		cells = OfflineRules.cells(state["pos"], state["orient"])
	var min_r: int = cells[0].x
	var max_r: int = cells[-1].x
	var min_c: int = cells[0].y
	var max_c: int = cells[-1].y
	var mid := Vector3((min_c + max_c) / 2.0, 0, (min_r + max_r) / 2.0)
	var top := 2.0 if state["orient"] == "STAND" else 1.0   # block height
	var lift := Vector3(0, top + 0.35, 0)
	var half_r := (max_r - min_r) / 2.0 + 0.55        # ring just outside the top face
	var half_c := (max_c - min_c) / 2.0 + 0.55
	var spots := {
		"U": mid + lift + Vector3(0, 0, -half_r), "D": mid + lift + Vector3(0, 0, half_r),
		"L": mid + lift + Vector3(-half_c, 0, 0), "R": mid + lift + Vector3(half_c, 0, 0),
	}
	for action in _hints:
		var node: Node3D = _hints[action]
		node.position = spots[action]
		node.rotation.y = YAW[action]
	_t = 0.0
	visible = true
