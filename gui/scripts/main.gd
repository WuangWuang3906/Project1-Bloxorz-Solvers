extends Node3D
## Scene setup and game flow.
##
## OFFLINE MODE: rules come from OfflineRules and Solve replays files in
## results/sample/. When bloxorz/server.py is ready, moves and solves must go
## through TCP (docs/ARCHITECTURE.md section 3).
##
## Command line (for automated checks), after `--`:
##   --level=N        start at level index N (0-based)
##   --moves=RDDR     play these moves on start
##   --screenshot=P   save a PNG to P after the moves, then quit

const CAM_FOV := 34.0
const CAM_DIR := Vector3(-0.18, 0.78, 0.52)

var repo_dir: String = ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
var level_files: Array = []
var level_index: int = 0
var level: LevelData
var state: Dictionary
var moves: int = 0
var busy: bool = false
var cam_yaw: float = 0.0

var board: Board
var block: Block
var ui: GameUI
var cam: Camera3D


func _ready() -> void:
	_setup_world()
	board = Board.new()
	add_child(board)
	block = Block.new()
	add_child(block)
	ui = GameUI.new()
	add_child(ui)
	ui.new_game_pressed.connect(func() -> void: _load_level(0))
	ui.restart_pressed.connect(func() -> void: _load_level(level_index))
	ui.level_selected.connect(_load_level)
	ui.solve_pressed.connect(_solve)
	get_viewport().size_changed.connect(_place_camera)

	_find_levels()
	var args := _cmd_args()
	_load_level(int(args.get("level", "0")))
	if args.has("moves") or args.has("screenshot"):
		_run_script(args)


# ---- world -------------------------------------------------------------

func _setup_world() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("2a1a52")
	sky_mat.sky_horizon_color = Color("d0708a")
	sky_mat.ground_horizon_color = Color("c8658a")
	sky_mat.ground_bottom_color = Color("6a3070")
	sky_mat.sun_angle_max = 20.0
	var sky := Sky.new()
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.9
	env.glow_enabled = true
	env.glow_intensity = 0.5
	env.glow_hdr_threshold = 1.0
	env.ssao_enabled = true
	env.ssao_intensity = 1.5
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color("ffd2a8")
	sun.light_energy = 1.4
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_max_distance = 60.0
	sun.rotation_degrees = Vector3(-50, -130, 0)
	add_child(sun)

	cam = Camera3D.new()
	cam.fov = CAM_FOV
	add_child(cam)


func _place_camera() -> void:
	if level == null:
		return
	var center := Vector3((level.cols - 1) / 2.0, 0, (level.rows - 1) / 2.0)
	var size := get_viewport().get_visible_rect().size
	var aspect: float = size.x / maxf(size.y, 1.0)
	var half_v := deg_to_rad(CAM_FOV) / 2.0
	var half_h := atan(tan(half_v) * aspect)
	var reach_x := level.cols / 2.0 + 0.3
	var reach_z := level.rows / 2.0 + 0.8
	var dist: float = max(reach_x / tan(half_h), reach_z / tan(half_v) * 1.25) * 1.12
	dist = max(dist, 8.0)
	var dir := CAM_DIR.normalized().rotated(Vector3.UP, cam_yaw)
	cam.position = center + dir * dist
	cam.look_at(center, Vector3.UP)


# ---- levels ------------------------------------------------------------

func _find_levels() -> void:
	var dir := repo_dir.path_join("levels")
	for f in DirAccess.get_files_at(dir):
		if f.begins_with("level") and f.ends_with(".json"):
			level_files.append(dir.path_join(f))
	level_files.sort()
	var names: Array = []
	for f in level_files:
		names.append(f.get_file().get_basename())
	ui.set_levels(names, 0)


func _load_level(index: int) -> void:
	if level_files.is_empty():
		ui.set_status("Không tìm thấy màn chơi trong levels/")
		return
	level_index = clampi(index, 0, level_files.size() - 1)
	level = LevelData.load_file(level_files[level_index])
	board.build(level)
	state = OfflineRules.initial_state(level)
	board.set_bridges(state["open"], false)
	block.set_state(state["pos"], state["orient"])
	moves = 0
	ui.set_moves(0)
	ui.set_title("BLOXORZ · %02d  %s" % [level.id, level.level_name])
	ui.select_level(level_index)
	ui.set_status("Offline mode — mũi tên/WASD để lăn, Q/E xoay camera, R chơi lại")
	_place_camera()


# ---- input & moves -----------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_UP, KEY_W:
			_try_move("U")
		KEY_DOWN, KEY_S:
			_try_move("D")
		KEY_LEFT, KEY_A:
			_try_move("L")
		KEY_RIGHT, KEY_D:
			_try_move("R")
		KEY_R:
			_load_level(level_index)
		KEY_Q:
			cam_yaw += PI / 2
			_place_camera()
		KEY_E:
			cam_yaw -= PI / 2
			_place_camera()


func _try_move(dir: String) -> void:
	if busy:
		return
	busy = true
	await _do_move(dir)
	busy = false


## Returns false when the block fell.
func _do_move(dir: String) -> bool:
	var res := OfflineRules.step(level, state, dir)
	await block.roll_to(dir, res["pos"], res["orient"])
	if "split_unsupported" in res["events"]:
		ui.set_status("Split switch chưa hỗ trợ ở offline mode")
	if res["state"] == null:
		ui.set_status("Rơi rồi! Chơi lại màn.")
		await block.fall()
		_load_level(level_index)
		return false
	state = res["state"]
	board.set_bridges(state["open"])
	moves += 1
	ui.set_moves(moves)
	if "win" in res["events"]:
		ui.set_status("Hoàn thành màn trong %d nước!" % moves)
		await block.sink()
	return true


# ---- solve (offline: replay sample results) ----------------------------

func _solve(algo: String) -> void:
	if busy:
		return
	var path := repo_dir.path_join("results/sample/level%02d_%s.json" % [level.id, algo])
	if not FileAccess.file_exists(path):
		ui.set_status("Chưa có server Python và chưa có file mẫu %s" % path.get_file())
		return
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	_load_level(level_index)
	ui.set_metrics(algo, data.get("metrics", {}))
	ui.set_status("Đang phát lại lời giải %s (file mẫu)..." % algo.to_upper())
	busy = true
	for a in data["actions"]:
		if not await _do_move(str(a)):
			break
		await get_tree().create_timer(0.08).timeout
	busy = false


# ---- automation --------------------------------------------------------

func _cmd_args() -> Dictionary:
	var out := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			var kv: PackedStringArray = a.substr(2).split("=", true, 1)
			out[kv[0]] = kv[1]
	return out


func _run_script(args: Dictionary) -> void:
	await get_tree().create_timer(0.5).timeout
	for ch in str(args.get("moves", "")):
		await _do_move(ch)
	await get_tree().create_timer(0.6).timeout
	if args.has("screenshot"):
		var img := get_viewport().get_texture().get_image()
		img.save_png(str(args["screenshot"]))
		get_tree().quit()
