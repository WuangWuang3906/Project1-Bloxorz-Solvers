extends Node3D
## Scene setup and game flow.
##
## Rules come from the Python server (bloxorz/server.py, TCP 127.0.0.1:5555)
## when it is running; otherwise from OfflineRules (temporary) and Solve
## replays files in results/sample/.
##
## Controls: arrow keys roll, Tab/Space switch cube, R restart, F11 full screen,
## mouse drag rotate camera, wheel zoom, PageUp/PageDown rotate 90°, Home reset camera.
## No WASD/Q/E: Vietnamese input tools (Unikey, Telex) rewrite letter keys.
## While a solution replays: F fast-forward (x1/x4/x16), Esc skip to the end.
##
## Restart, New game, choosing a level or pressing a solver button starts a new
## "epoch": the running solve, replay and animations of the old one stop at once
## (every coroutine checks `ep != _epoch` after each await and quits quietly).
##
## Command line (for automated checks), after `--`:
##   --level=N         start at level index N (0-based); skips the level screen
##   --moves=RDDR      play these moves (T = switch cube)
##   --shot-at=SEC     take the screenshot SEC seconds into the last move
##   --yaw=DEG --pitch=DEG --zoom=F   camera override
##   --solve=ALGO      press a Solve button first
##   --skip-at=SEC     press Esc SEC seconds into the replay
##   --restart-at=SEC  press R SEC seconds after the solve button
##   --help            open the how-to-play board
##   --settings        open the settings board
##   --markers=dam|nhat  switch colour style for this run
##   --shot-during=SEC take the screenshot SEC seconds after the solve button, then quit
##   --goal=ring|plain   goal look
##   --select          open the level screen
##   --screenshot=P    save a PNG to P, then quit

const DEFAULT_YAW := -19.0
const DEFAULT_PITCH := 55.0
const CAM_FOV := 34.0
const REPLAY_SPEEDS := [1.0, 4.0, 16.0]
const NO_SOURCE_MSG := "Không thấy mã nguồn Python — hãy đọc README, đặt mã nguồn đúng chỗ\n(Bloxorz.exe trong gui\\export\\ của thư mục mã nguồn) để dùng các thuật toán"

var repo_dir: String = _find_repo_dir()
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
var _epoch: int = 0
var _server_pid: int = -1          # Python server started by the game itself

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
var hints: KeyHints
var scenery: Scenery


func _ready() -> void:
	var early := _cmd_args()
	Board.goal_style = str(early.get("goal", Board.goal_style))
	_setup_world()
	board = Board.new()
	add_child(board)
	block = Block.new()
	add_child(block)
	hints = KeyHints.new()
	add_child(hints)
	ui = GameUI.new()
	add_child(ui)
	net = NetClient.new()
	add_child(net)
	ui.new_game_pressed.connect(func() -> void: _restart(0))
	ui.restart_pressed.connect(func() -> void: _restart(level_index))
	ui.level_selected.connect(_restart)
	ui.solve_pressed.connect(_solve)
	ui.marker_style_changed.connect(_on_marker_style)
	Board.marker_style = _load_setting("marker_style", "dam")
	ui.set_marker_style(Board.marker_style)
	ui.compass_clicked.connect(func() -> void:
		cam_yaw = DEFAULT_YAW
		cam_pitch = DEFAULT_PITCH
		cam_zoom = 1.0)
	ui.compass_visibility_changed.connect(_on_compass_visibility)
	var show_compass := _load_setting("compass", "an") != "an"
	ui.set_compass_visible(show_compass)

	_find_levels()
	var args := _cmd_args()
	# Solvers only work with the source next to the game (README); otherwise
	# stay offline, even if some other server happens to be running.
	if _has_source():
		online = await net.try_connect()
		if not online:
			online = await _start_server()
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


## No server running but the Python code is next to the game (repo layout):
## start `python -m bloxorz.server` in the background and connect to it.
func _start_server() -> bool:
	if not _has_source():
		return false
	OS.set_environment("PYTHONPATH", repo_dir)
	_server_pid = OS.create_process("python", ["-m", "bloxorz.server"])
	if _server_pid <= 0:
		return false
	ui.show_loading("ĐANG KHỞI ĐỘNG", "Đang bật server Python...")
	for i in 20:   # Python needs a moment to start
		await get_tree().create_timer(0.25).timeout
		if await net.try_connect(0.3):
			ui.hide_loading()
			return true
	ui.hide_loading()
	return false


const SETTINGS_PATH := "user://settings.cfg"


func _on_marker_style(style: String) -> void:
	board.set_marker_style(style)
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("display", "marker_style", style)
	cfg.save(SETTINGS_PATH)


func _on_compass_visibility(show: bool) -> void:
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS_PATH)
	cfg.set_value("display", "compass", "hien" if show else "an")
	cfg.save(SETTINGS_PATH)


func _load_setting(key: String, fallback: String) -> String:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) != OK:
		return fallback
	var v: String = str(cfg.get_value("display", key, fallback))
	return v if not v.is_empty() else fallback


func _has_source() -> bool:
	return FileAccess.file_exists(repo_dir.path_join("bloxorz/server.py"))


func _exit_tree() -> void:
	if _server_pid > 0:
		OS.kill(_server_pid)


# ---- world & camera ----------------------------------------------------

func _setup_world() -> void:
	# deep-jungle mood: green-gold sky, warm low sun, mist between the canopies
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("6fa8a0")
	sky_mat.sky_horizon_color = Color("f1e3a8")
	sky_mat.ground_horizon_color = Color("9cc48a")
	sky_mat.ground_bottom_color = Color("1d3a22")
	sky_mat.sun_angle_max = 25.0
	var sky := Sky.new()
	sky.sky_material = sky_mat

	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c9dcb5")
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 0.8
	env.glow_enabled = true
	env.glow_intensity = 0.25
	env.glow_bloom = 0.0
	env.glow_hdr_threshold = 0.9
	env.ssao_enabled = true
	env.ssao_intensity = 1.6
	env.adjustment_enabled = true
	env.adjustment_saturation = 1.2
	env.adjustment_contrast = 1.08
	env.fog_enabled = true                       # mist pooling below the board
	env.fog_light_color = Color("b9cfb2")   # pale mist in the valley
	env.fog_density = 0.0012
	env.fog_height = -16.0
	env.fog_height_density = 0.03
	env.fog_sky_affect = 0.3
	env.fog_aerial_perspective = 0.15
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var sun := DirectionalLight3D.new()
	sun.light_color = Color("ffe0a8")
	sun.light_energy = 1.6
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

	scenery = Scenery.new()
	add_child(scenery)


func _process(delta: float) -> void:
	var k := 1.0 - exp(-delta * 12.0)
	_cur_yaw = lerpf(_cur_yaw, cam_yaw, k)
	_cur_pitch = lerpf(_cur_pitch, cam_pitch, k)
	_cur_zoom = lerpf(_cur_zoom, cam_zoom, k)
	_place_camera()
	_update_compass()
	_update_hints()


## Arrow-key hints around the block, only while the player can act.
func _update_hints() -> void:
	if hints == null:
		return
	var idle := level != null and not busy and not replaying and not solving
	idle = idle and not ui.is_level_select_open() and not state.is_empty()
	idle = idle and not OfflineRules.is_goal(level, state)
	hints.up_action = _screen_action(0)
	hints.show_for(state if idle else null)


## Arrow keys follow the screen, not the board: ↑ always rolls the block
## "into" the screen, whatever way the camera is turned. key: 0 = ↑, 1 = →,
## 2 = ↓, 3 = ←. The board move whose on-screen direction is closest to
## "up" goes to ↑; the others follow clockwise (U, R, D, L).
func _screen_action(key: int) -> String:
	const ORDER := ["U", "R", "D", "L"]
	if cam == null or level == null:
		return ORDER[key]
	var center := Vector3((level.cols - 1) / 2.0, 0, (level.rows - 1) / 2.0)
	var c2 := cam.unproject_position(center)
	var best := 0
	var best_dot := -INF
	for i in 4:
		var d: Vector2 = OfflineRules.DIRS[ORDER[i]]
		var p := cam.unproject_position(center + Vector3(d.y, 0, d.x)) - c2
		var dot := p.normalized().dot(Vector2(0, -1))
		if dot > best_dot:
			best_dot = dot
			best = i
	return ORDER[(best + key) % 4]


func _snap_camera() -> void:
	_cur_yaw = cam_yaw
	_cur_pitch = cam_pitch
	_cur_zoom = cam_zoom
	_place_camera()
	_update_compass()


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


func _update_compass() -> void:
	if cam == null or level == null or ui == null:
		return
	var center := Vector3((level.cols - 1) / 2.0, 0, (level.rows - 1) / 2.0)
	var p_center := cam.unproject_position(center)
	var p_u := cam.unproject_position(center + Vector3(0, 0, -1.0))
	var p_r := cam.unproject_position(center + Vector3(1.0, 0, 0))
	var p_d := cam.unproject_position(center + Vector3(0, 0, 1.0))
	var p_l := cam.unproject_position(center + Vector3(-1.0, 0, 0))

	var du := p_u - p_center
	var dr := p_r - p_center
	var dd := p_d - p_center
	var dl := p_l - p_center

	var dir_u := du.normalized() if du.length_squared() > 0.0001 else Vector2(0, -1)
	var dir_r := dr.normalized() if dr.length_squared() > 0.0001 else Vector2(1, 0)
	var dir_d := dd.normalized() if dd.length_squared() > 0.0001 else Vector2(0, 1)
	var dir_l := dl.normalized() if dl.length_squared() > 0.0001 else Vector2(-1, 0)

	ui.set_compass_directions(dir_u, dir_r, dir_d, dir_l)


# ---- levels ------------------------------------------------------------

## Repo root = the folder with bloxorz/server.py and levels/. In the editor it is
## the parent of gui/; the exported .exe searches upward from its own folder.
## Not found (e.g. .exe alone in Downloads): the packed levels are used, offline.
static func _find_repo_dir() -> String:
	if OS.has_feature("editor"):
		return ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	var dir := OS.get_executable_path().get_base_dir()
	for i in 4:
		if FileAccess.file_exists(dir.path_join("bloxorz/server.py")):
			return dir
		dir = dir.get_base_dir()
	return OS.get_executable_path().get_base_dir()


func _find_levels() -> void:
	var dir := repo_dir.path_join("levels")
	if not DirAccess.dir_exists_absolute(dir):
		dir = "res://levels"   # copies packed into the .exe (tools/build_exe.py)
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


## Drop whatever is running (solve, replay, animation) and start a new epoch.
func _new_epoch() -> void:
	_epoch += 1
	net.epoch = _epoch
	busy = false
	replaying = false
	solving = false
	skip_requested = false
	Engine.time_scale = 1.0
	block.stop_all()
	ui.hide_loading()


## Restart / New game / level chosen: stop everything, then load the level.
func _restart(index: int) -> void:
	_new_epoch()
	await _load_level(index)


func _load_level(index: int) -> void:
	var ep := _epoch
	if not online and not replaying and _has_source():   # server may have been started after the game
		online = await net.try_connect(0.3)
		ui.set_mode(online)
		if ep != _epoch:
			return
	if level_files.is_empty():
		ui.set_status("Không tìm thấy màn chơi (thư mục levels/)")
		return
	level_index = clampi(index, 0, level_files.size() - 1)
	level = LevelData.load_file(level_files[level_index])
	board.build(level)
	scenery.build(Vector3((level.cols - 1) / 2.0, 0, (level.rows - 1) / 2.0), maxf(level.cols, level.rows) / 2.0, level)
	state = OfflineRules.initial_state(level)
	if online:
		# Send the level itself, not a file name: a server started from another
		# (older) copy of the repo would otherwise solve a different board.
		var r := await net.request({"cmd": "load", "level": level.raw}, ep)
		if ep != _epoch or r.has("stale"):
			return
		if r.get("ok", false):
			state = NetClient.state_from_json(r["state"])
		else:
			_go_offline(r)
	board.set_bridges(state["open"], false)
	block.set_state(state)
	moves = 0
	ui.set_moves(0)
	ui.set_title("BLOXORZ · %02d  %s" % [level.id, level.level_name])
	if _has_source():
		ui.set_status("")   # controls are in the "?" board, keep the screen clean
	else:
		ui.set_status(NO_SOURCE_MSG)
	_place_camera()
	_update_compass()


func _go_offline(reply: Dictionary) -> void:
	online = false
	ui.set_mode(false)
	ui.set_status("Mất kết nối server (%s) — chuyển sang offline" % reply.get("error", "no reply"))


# ---- input -------------------------------------------------------------

func _unhandled_input(event: InputEvent) -> void:
	if ui.is_level_select_open():
		return
	if ui.is_settings_open():
		if event is InputEventKey and event.pressed and event.keycode in [KEY_ESCAPE, KEY_ENTER]:
			ui.hide_settings()
		return
	if ui.is_help_open():
		if event is InputEventKey and event.pressed and event.keycode in [KEY_ESCAPE, KEY_ENTER, KEY_SPACE]:
			ui.hide_help()
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
	if event.keycode == KEY_F11:
		var full := DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
		return
	if event.keycode == KEY_R:   # works during a solve or a replay too
		_restart(level_index)
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
		KEY_UP:
			_try_move(_screen_action(0))
		KEY_RIGHT:
			_try_move(_screen_action(1))
		KEY_DOWN:
			_try_move(_screen_action(2))
		KEY_LEFT:
			_try_move(_screen_action(3))
		KEY_TAB, KEY_SPACE:
			_try_move("SWITCH")
		KEY_PAGEUP:
			cam_yaw += 90.0
		KEY_PAGEDOWN:
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
	var ep := _epoch
	await _do_move(action)
	if ep == _epoch:
		busy = false


## Ask the rules (server or offline) for the next state and animate it.
## Returns false when the block fell.
func _do_move(action: String) -> bool:
	var ep := _epoch
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
		var r := await net.request({"cmd": "move", "action": action}, ep)
		if ep != _epoch or r.has("stale"):
			return false
		if r.is_empty() or not r.get("ok", false):
			_go_offline(r)
			return await _do_move(action)
		next = NetClient.state_from_json(r.get("state"))
		events = r.get("events", [])
	else:
		var res := OfflineRules.step(level, prev, action)
		next = res["state"]
		events = res["events"]

	var ok := await _animate(prev, next, action)
	if ep != _epoch:
		return false
	if not ok:
		if replaying:
			ui.set_status("Lời giải không khớp màn này — server Python có thể là bản cũ: tắt nó và mở lại game")
			await get_tree().create_timer(3.0).timeout
			if ep != _epoch:
				return false
		else:
			ui.set_status("Rơi rồi! Chơi lại màn.")
		await _load_level(level_index)
		return false
	state = next
	board.set_bridges(state["open"])
	moves += 1
	ui.set_moves(moves)
	if "merge" in events:
		ui.set_status("Hai khối đã nhập lại!")
	elif "split" in events and not replaying:
		ui.set_status("Khối đã tách! Bấm Tab để đổi khối điều khiển")
	if OfflineRules.is_goal(level, state):
		ui.set_status("Hoàn thành màn trong %d nước!" % moves)
		await block.sink()
		if ep != _epoch:
			return false
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
	if not _has_source():
		ui.set_status(NO_SOURCE_MSG)
		return
	_new_epoch()   # another solver button = stop the current solve/replay first
	var ep := _epoch
	busy = true
	await _load_level(level_index)   # also retries the server if offline
	if ep != _epoch:
		return
	var result: Dictionary = {}
	var measuring := false
	if online:
		var r := await net.request({"cmd": "solve_start", "algo": algo}, ep)
		if ep != _epoch or r.has("stale"):
			return
		if not r.get("ok", false):
			ui.set_status("Server báo lỗi: %s" % r.get("error", "no reply"))
			busy = false
			return
		solving = true
		ui.clear_metrics()
		var algo_name := "A*" if algo == "astar" else algo.to_upper()
		var t0 := Time.get_ticks_msec()
		var last_poll: Dictionary = {}
		while true:
			ui.show_loading("ĐANG GIẢI BẰNG %s" % algo_name, _progress_text(last_poll, t0),
				_progress_frac(last_poll))
			await get_tree().create_timer(0.15).timeout
			if ep != _epoch:
				return
			var p := await net.request({"cmd": "solve_poll"}, ep)
			if ep != _epoch or p.has("stale"):
				return
			if p.is_empty() or not p.get("ok", false):
				_go_offline(p)
				break
			last_poll = p
			var phase: String = p.get("phase", "")
			if phase == "measuring" or phase == "done":
				result = p["result"]
				measuring = phase == "measuring"
				break
			if phase != "solving":
				ui.set_status("Server báo lỗi: %s" % str(p.get("error", phase)))
				break
		solving = false
		if not result.is_empty():
			# Finished: fill the bar to 100 % and let it be seen (small levels
			# are solved in a few ms and would otherwise flash at 0 %).
			var found_text := "Đã tìm thấy đường đi!" if result.get("found", false) else "Không có đường đi."
			ui.show_loading("ĐANG GIẢI BẰNG %s" % algo_name, "%s (%.1f giây)" % [
				found_text, (Time.get_ticks_msec() - t0) / 1000.0], 1.0)
			await get_tree().create_timer(0.7).timeout
			if ep != _epoch:
				return
		ui.hide_loading()
	else:
		var path := repo_dir.path_join("results/sample/level%02d_%s.json" % [level.id, algo])
		if FileAccess.file_exists(path):
			result = JSON.parse_string(FileAccess.get_file_as_string(path))
		else:
			ui.set_status("Offline: chưa bật được server Python (lệnh python có chạy được không?) — xem README")
	if not result.is_empty():
		ui.set_metrics(algo, result.get("metrics", {}))
		if not result.get("found", false):
			ui.set_status("%s không tìm được lời giải" % algo.to_upper())
		else:
			if measuring:
				_wait_peak(algo, ep)
			await _replay(algo, result["actions"], ep)
	if ep == _epoch:
		busy = false


## Share of the level's reachable states expanded so far, -1 if unknown.
func _progress_frac(p: Dictionary) -> float:
	if p.is_empty():
		return 0.0   # no poll answer yet: start the bar at 0 %
	var total: Variant = p.get("total")
	if total == null or int(total) <= 0:
		return -1.0
	return float(p.get("progress", 0)) / float(total)


## Players only need the time; the bar shows the percentage.
func _progress_text(_p: Dictionary, t0: int) -> String:
	return "Đã chạy %.1f giây" % ((Time.get_ticks_msec() - t0) / 1000.0)


## The server is still measuring peak memory after the actions arrived:
## keep polling in the background (between replay moves) and fill it in.
func _wait_peak(algo: String, ep: int) -> void:
	while ep == _epoch:
		await get_tree().create_timer(0.3).timeout
		if ep != _epoch:
			return
		var p := await net.request({"cmd": "solve_poll"}, ep)
		if ep != _epoch or p.has("stale") or not p.get("ok", false):
			return
		if p.get("phase") == "done":
			ui.set_metrics(algo, p["result"]["metrics"])
			return
		if p.get("phase") != "measuring":
			return


func _replay(algo: String, actions: Array, ep: int) -> void:
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
		if ep != _epoch:
			return
		i += 1
		await get_tree().create_timer(0.08).timeout
		if ep != _epoch:
			return
	Engine.time_scale = 1.0
	if skip_requested and i < actions.size():
		await _jump(actions.slice(i), ep)
	if ep == _epoch:
		replaying = false


var _replay_algo: String = ""


func _replay_hint() -> void:
	ui.set_status("Phát lại %s · x%d · F tua nhanh · Esc tới cuối" % [_replay_algo, int(REPLAY_SPEEDS[replay_speed])])


## Apply the remaining moves without animation (Esc during a replay).
func _jump(rest: Array, ep: int) -> void:
	var next: Variant = state
	if online:
		var r := await net.request({"cmd": "apply", "actions": rest}, ep)
		if ep != _epoch or r.has("stale"):
			return
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
	if args.has("help"):
		ui.show_help()
	if args.has("settings"):
		ui.show_settings()
	if args.has("markers"):
		_on_marker_style(str(args["markers"]))
		ui.set_marker_style(str(args["markers"]))
	if args.has("shot-during"):
		_shot_later(float(args["shot-during"]), args["screenshot"])
	if args.has("restart-at"):
		_restart_later(float(args["restart-at"]))
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


func _shot_later(sec: float, path: String) -> void:
	await get_tree().create_timer(sec).timeout
	_save_shot(path)


func _restart_later(sec: float) -> void:
	await get_tree().create_timer(sec).timeout
	_restart(level_index)


func _save_shot(path: String) -> void:
	get_viewport().get_texture().get_image().save_png(path)
	get_tree().quit()
