extends Node3D
## Scene setup and game flow.
##
## Rules come from the Python server (bloxorz/server.py, TCP 127.0.0.1:5555)
## when it is running; otherwise from OfflineRules (temporary) and Solve
## replays files in results/sample/.
##
## Controls: arrows/WASD roll, Tab/Space switch cube, R restart,
## mouse drag rotate camera, wheel zoom, Q/E rotate 90°, Home reset camera.
## While a solution replays: F fast-forward (x1/x4/x16), Esc skip to the end.
##
## Command line (for automated checks), after `--`:
##   --level=N         start at level index N (0-based); skips the level screen
##   --moves=RDDR      play these moves (T = switch cube)
##   --shot-at=SEC     take the screenshot SEC seconds into the last move
##   --yaw=DEG --pitch=DEG --zoom=F   camera override
##   --solve=ALGO      press a Solve button first
##   --skip-at=SEC     press Esc SEC seconds into the replay
##   --goal=ring|plain   goal look
##   --select          open the level screen
##   --screenshot=P    save a PNG to P, then quit

const DEFAULT_YAW := -19.0
const DEFAULT_PITCH := 55.0
const CAM_FOV := 34.0
const REPLAY_SPEEDS := [1.0, 4.0, 16.0]

var repo_dir: String = ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
var level_files: Array = []
var level_index: int = 0
var level: LevelData
var state: Dictionary
var moves: int = 0
var busy: bool = false
var online: bool = false
var replaying: bool = false
var replay_speed: int = 0          # index in REPLAY_SPEEDS
var skip_requested: bool = false
var solving: bool = false

var cam_yaw: float = DEFAULT_YAW
var cam_pitch: float = DEFAULT_PITCH
var cam_zoom: float = 1.0
var _cur_yaw: float = DEFAULT_YAW
var _cur_pitch: float = DEFAULT_PITCH
var _cur_zoom: float = 1.0
var _dragging: bool = false

var board: Board
var block: Block
var ui: GameUI
var net: NetClient
var cam: Camera3D


func _ready() -> void:
	var early := _cmd_args()
	Board.goal_style = str(early.get("goal", Board.goal_style))
	_setup_world()
	board = Board.new()
	add_child(board)
	block = Block.new()
	add_child(block)
	ui = GameUI.new()
	add_child(ui)
	net = NetClient.new()
	add_child(net)
	ui.new_game_pressed.connect(func() -> void: _load_level(0))
	ui.restart_pressed.connect(func() -> void: _load_level(level_index))
	ui.level_selected.connect(_load_level)
	ui.solve_pressed.connect(_solve)

	_find_levels()
	var args := _cmd_args()
	online = await net.try_connect()
	ui.set_mode(online)
	await _load_level(int(args.get("level", "0")))
	if args.has("yaw"):
		cam_yaw = float(args["yaw"])
	if args.has("pitch"):
		cam_pitch = float(args["pitch"])
	if args.has("zoom"):
		cam_zoom = float(args["zoom"])
	_snap_camera()
	if args.is_empty() or args.has("select"):
		ui.show_level_select()
	if args.has("screenshot"):
		_run_script(args)


# ---- world & camera ----------------------------------------------------

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

	var fill := DirectionalLight3D.new()   # soft front light from the camera side
	fill.light_color = Color("fff1e6")
	fill.light_energy = 0.55
	fill.rotation_degrees = Vector3(-35, -15, 0)
	add_child(fill)

	cam = Camera3D.new()
	cam.fov = CAM_FOV
	add_child(cam)


func _process(delta: float) -> void:
	var k := 1.0 - exp(-delta * 12.0)
	_cur_yaw = lerpf(_cur_yaw, cam_yaw, k)
	_cur_pitch = lerpf(_cur_pitch, cam_pitch, k)
	_cur_zoom = lerpf(_cur_zoom, cam_zoom, k)
	_place_camera()


func _snap_camera() -> void:
	_cur_yaw = cam_yaw
	_cur_pitch = cam_pitch
	_cur_zoom = cam_zoom
	_place_camera()


func _place_camera() -> void:
	if level == null:
		return
	var center := Vector3((level.cols - 1) / 2.0, 0, (level.rows - 1) / 2.0)
	var size := get_viewport().get_visible_rect().size
	var aspect: float = size.x / maxf(size.y, 1.0)
	var half_v := deg_to_rad(CAM_FOV) / 2.0
	var half_h := atan(tan(half_v) * aspect)
	var reach := maxf(level.cols, level.rows) / 2.0 + 0.3
	var dist: float = maxf(reach / tan(half_h), (level.rows / 2.0 + 0.8) / tan(half_v) * 1.25) * 1.12
	dist = maxf(dist, 8.0) * _cur_zoom
	var yaw := deg_to_rad(_cur_yaw)
	var pitch := deg_to_rad(_cur_pitch)
	var dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch))
	cam.position = center + dir * dist
	cam.look_at(center, Vector3.UP)


# ---- levels ------------------------------------------------------------

func _find_levels() -> void:
	var dir := repo_dir.path_join("levels")
	for f in DirAccess.get_files_at(dir):
		if f.begins_with("level") and f.ends_with(".json"):
			level_files.append(dir.path_join(f))
	level_files.sort()
	var infos: Array = []
	for f in level_files:
		var lv := LevelData.load_file(f)
		if lv != null:
			infos.append({"id": lv.id, "name": lv.level_name, "group": lv.group})
	ui.set_levels(infos)


func _load_level(index: int) -> void:
	if not online and not replaying:   # server may have been started after the game
		online = await net.try_connect(0.3)
		ui.set_mode(online)
	if level_files.is_empty():
		ui.set_status("Không tìm thấy màn chơi trong levels/")
		return
	level_index = clampi(index, 0, level_files.size() - 1)
	level = LevelData.load_file(level_files[level_index])
	board.build(level)
	state = OfflineRules.initial_state(level)
	if online:
		var rel: String = "levels/" + level_files[level_index].get_file()
		var r := await net.request({"cmd": "load", "path": rel})
		if r.get("ok", false):
			state = NetClient.state_from_json(r["state"])
		else:
			_go_offline(r)
	board.set_bridges(state["open"], false)
	block.set_state(state)
	moves = 0
	ui.set_moves(0)
	ui.set_title("BLOXORZ · %02d  %s" % [level.id, level.level_name])
	ui.set_status("Mũi tên/WASD lăn · Tab đổi khối · kéo chuột xoay · cuộn để zoom · R chơi lại")
	_place_camera()


func _go_offline(reply: Dictionary) -> void:
	online = false
	ui.set_mode(false)
	ui.set_status("Mất kết nối server (%s) — chuyển sang offline" % reply.get("error", "no reply"))


# ---- input -------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if ui.is_level_select_open():
		return
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_dragging = mb.pressed
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			cam_zoom = clampf(cam_zoom * 0.9, 0.45, 2.2)
		elif mb.pressed and mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			cam_zoom = clampf(cam_zoom * 1.1, 0.45, 2.2)
		return
	if event is InputEventMouseMotion and _dragging:
		var mm := event as InputEventMouseMotion
		cam_yaw -= mm.relative.x * 0.3
		cam_pitch = clampf(cam_pitch + mm.relative.y * 0.25, 20.0, 88.0)
		return
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if replaying:
		if event.keycode == KEY_F:
			replay_speed = (replay_speed + 1) % REPLAY_SPEEDS.size()
			Engine.time_scale = REPLAY_SPEEDS[replay_speed]
			_replay_hint()
		elif event.keycode == KEY_ESCAPE:
			skip_requested = true
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
		KEY_TAB, KEY_SPACE:
			_try_move("SWITCH")
		KEY_R:
			_load_level(level_index)
		KEY_Q:
			cam_yaw += 90.0
		KEY_E:
			cam_yaw -= 90.0
		KEY_HOME:
			cam_yaw = DEFAULT_YAW
			cam_pitch = DEFAULT_PITCH
			cam_zoom = 1.0


# ---- moves -------------------------------------------------------------

func _try_move(action: String) -> void:
	if busy:
		return
	busy = true
	await _do_move(action)
	busy = false


## Ask the rules (server or offline) for the next state and animate it.
## Returns false when the block fell.
func _do_move(action: String) -> bool:
	var prev := state
	if prev["orient"] == "SPLIT" and action != "SWITCH":
		var target: Vector2i = prev["cubes"][prev["active"]] + OfflineRules.DIRS[action]
		if target == prev["cubes"][1 - prev["active"]]:
			ui.set_status("Không thể lăn đè lên khối kia")
			return true
	elif prev["orient"] != "SPLIT" and action == "SWITCH":
		return true

	var next: Variant
	var events: Array
	if online:
		var r := await net.request({"cmd": "move", "action": action})
		if r.is_empty() or not r.get("ok", false):
			_go_offline(r)
			return await _do_move(action)
		next = NetClient.state_from_json(r.get("state"))
		events = r.get("events", [])
	else:
		var res := OfflineRules.step(level, prev, action)
		next = res["state"]
		events = res["events"]

	if not await _animate(prev, next, action):
		ui.set_status("Rơi rồi! Chơi lại màn.")
		await _load_level(level_index)
		return false
	state = next
	board.set_bridges(state["open"])
	moves += 1
	ui.set_moves(moves)
	if "merge" in events:
		ui.set_status("Hai khối đã nhập lại!")
	elif "split" in events:
		ui.set_status("Khối đã tách! Tab/Space để đổi khối điều khiển")
	if OfflineRules.is_goal(level, state):
		ui.set_status("Hoàn thành màn trong %d nước!" % moves)
		await block.sink()
	return true


## Animate prev -> next. Returns false when the block fell (next == null).
func _animate(prev: Dictionary, next: Variant, action: String) -> bool:
	if action == "SWITCH":
		if next != null:
			block.set_active(next["active"])
		return next != null
	if prev["orient"] != "SPLIT":
		var r := OfflineRules.roll(prev["pos"], prev["orient"], action)
		await block.roll_to(action, r[0], r[1])
		if next == null:
			var cs := OfflineRules.cells(r[0], r[1])
			await block.tumble(block.body, cs, _support_flags(cs, r[1] == "STAND", prev["open"]), action)
			return false
		if next["orient"] == "SPLIT":
			await block.split_into(next)
		return true
	var a: int = prev["active"]
	var target: Vector2i = prev["cubes"][a] + OfflineRules.DIRS[action]
	await block.cube_roll(action)
	if next == null:
		await block.tumble(block.cubes[a], [target], _support_flags([target], false, prev["open"]), action)
		return false
	block.set_state(next, true)
	return true


## Which cells can hold the block. If all could (e.g. a bridge closed right
## under it), treat every cell as unsupported so it drops straight down.
func _support_flags(cs: Array, standing: bool, open: Dictionary) -> Array:
	var ok: Array = []
	for p in cs:
		ok.append(OfflineRules.cell_ok(level, p, standing, open))
	if not ok.has(false):
		ok.fill(false)
	return ok


# ---- solve -------------------------------------------------------------

func _solve(algo: String) -> void:
	if busy:
		return
	busy = true
	var result: Dictionary = {}
	await _load_level(level_index)   # also retries the server if offline
	if online:
		solving = true
		_tick_solving(algo)
		var r := await net.request({"cmd": "solve", "algo": algo})
		solving = false
		if r.get("ok", false):
			result = r["result"]
		else:
			ui.set_status("Server báo lỗi: %s" % r.get("error", "no reply"))
	else:
		var path := repo_dir.path_join("results/sample/level%02d_%s.json" % [level.id, algo])
		if FileAccess.file_exists(path):
			result = JSON.parse_string(FileAccess.get_file_as_string(path))
		else:
			ui.set_status("Offline: chưa có server Python và chưa có file mẫu %s" % path.get_file())
	if not result.is_empty():
		ui.set_metrics(algo, result.get("metrics", {}))
		if not result.get("found", false):
			ui.set_status("%s không tìm được lời giải" % algo.to_upper())
		else:
			await _load_level(level_index)
			await _replay(algo, result["actions"])
	busy = false


## Show the elapsed time while the server is solving (big levels take seconds).
func _tick_solving(algo: String) -> void:
	var t0 := Time.get_ticks_msec()
	while solving:
		ui.set_status("Python đang giải bằng %s... %.1f s" % [algo.to_upper(), (Time.get_ticks_msec() - t0) / 1000.0])
		await get_tree().create_timer(0.2).timeout


func _replay(algo: String, actions: Array) -> void:
	replaying = true
	skip_requested = false
	replay_speed = 0
	Engine.time_scale = 1.0
	_replay_algo = "%s (%d nước)" % ["A*" if algo == "astar" else algo.to_upper(), actions.size()]
	_replay_hint()
	var i := 0
	while i < actions.size() and not skip_requested:
		if not await _do_move(str(actions[i])):
			break
		i += 1
		await get_tree().create_timer(0.08).timeout
	Engine.time_scale = 1.0
	if skip_requested and i < actions.size():
		await _jump(actions.slice(i))
	replaying = false


var _replay_algo: String = ""


func _replay_hint() -> void:
	ui.set_status("Phát lại %s · x%d · F tua nhanh · Esc tới cuối" % [_replay_algo, int(REPLAY_SPEEDS[replay_speed])])


## Apply the remaining moves without animation (Esc during a replay).
func _jump(rest: Array) -> void:
	var next: Variant = state
	if online:
		var r := await net.request({"cmd": "apply", "actions": rest})
		next = NetClient.state_from_json(r.get("state")) if r.get("ok", false) else null
	else:
		for a in rest:
			next = OfflineRules.step(level, next, str(a))["state"]
			if next == null:
				break
	if next == null:
		ui.set_status("Không bỏ qua được (lời giải lỗi?) — chơi lại màn")
		await _load_level(level_index)
		return
	state = next
	board.set_bridges(state["open"], false)
	block.set_state(state)
	moves += rest.size()
	ui.set_moves(moves)
	if OfflineRules.is_goal(level, state):
		ui.set_status("Hoàn thành màn trong %d nước!" % moves)
		await block.sink()


# ---- automation --------------------------------------------------------

func _cmd_args() -> Dictionary:
	var out := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--"):
			var kv: PackedStringArray = a.substr(2).split("=", true, 1)
			out[kv[0]] = kv[1] if kv.size() > 1 else ""
	return out


func _run_script(args: Dictionary) -> void:
	await get_tree().create_timer(0.5).timeout
	var seq: Array = []
	for ch in str(args.get("moves", "")):
		seq.append("SWITCH" if ch == "T" else ch)
	if args.has("skip-at"):
		_skip_later(float(args["skip-at"]))
	if args.has("solve"):
		await _solve(str(args["solve"]))
	for i in seq.size():
		if i == seq.size() - 1 and args.has("shot-at"):
			_do_move(seq[i])
			await get_tree().create_timer(float(args["shot-at"])).timeout
			_save_shot(args["screenshot"])
			return
		await _do_move(seq[i])
	await get_tree().create_timer(0.6).timeout
	_save_shot(args["screenshot"])


func _skip_later(sec: float) -> void:
	while not replaying:
		await get_tree().process_frame
	await get_tree().create_timer(sec).timeout
	skip_requested = true


func _save_shot(path: String) -> void:
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
