class_name GameUI
extends CanvasLayer
## Glass-style HUD (title, controls, solver buttons, metrics, status) and the
## level-select screen.

signal new_game_pressed
signal restart_pressed
signal level_selected(index: int)
signal solve_pressed(algo: String)
signal marker_style_changed(style: String)

const ALGOS := [["BFS", "bfs"], ["DFS", "dfs"], ["UCS", "ucs"], ["A*", "astar"]]
const GROUP_COLORS := {
	"basic": Color("f6efe6"), "fragile": Color("ffb347"), "switch": Color("7fd6ff"), "split": Color("ffd23f"),
}

var _title: Label
var _moves: Label
var _mode: Label
var _metrics: Label
var _status: Label
var _select: Control
var _grid: GridContainer
<<<<<<< Updated upstream
=======
var _help: Control
var _settings: Control
var _style_buttons: Dictionary = {}   # "dam"/"nhat" -> Button
var _loading: Control
var _loading_title: Label
var _loading_detail: Label
var _loading_bar: ProgressBar
var _loading_t: float = 0.0
var _loading_frac: float = -1.0   # <0: unknown total, bar sweeps back and forth

const HELP_LINES := [
	["Mũi tên ↑ ↓ ← →", "Lăn khối"],
	["Tab / Space", "Đổi khối điều khiển (khi đã tách)"],
	["R", "Chơi lại màn (huỷ luôn việc đang giải)"],
	["Kéo chuột · Cuộn chuột", "Xoay góc nhìn · phóng to/thu nhỏ"],
	["PageUp / PageDown · Home", "Xoay 90° · về góc mặc định"],
	["F11", "Bật/tắt toàn màn hình"],
	["BFS · DFS · UCS · A*", "Máy tự giải rồi lăn tới đích"],
	["F · Esc (khi phát lại)", "Tua nhanh · nhảy tới cuối"],
]
>>>>>>> Stashed changes


func _ready() -> void:
	var left := _panel(Control.PRESET_TOP_LEFT)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	left.add_child(box)
	_title = _label("BLOXORZ", 24, YELLOW, 8)
	box.add_child(_title)

	var row1 := HBoxContainer.new()
	box.add_child(row1)
	row1.add_child(_button("NEW GAME", func() -> void: new_game_pressed.emit()))
	row1.add_child(_button("RESTART", func() -> void: restart_pressed.emit()))
	row1.add_child(_button("LEVELS", show_level_select))

	var row2 := HBoxContainer.new()
	box.add_child(row2)
	for a in ALGOS:
		var algo: String = a[1]
		row2.add_child(_button(a[0], func() -> void: solve_pressed.emit(algo), true))
	var row3 := HBoxContainer.new()
	row3.add_theme_constant_override("separation", 16)
	box.add_child(row3)
	_moves = _label("Moves: 0", 15)
	row3.add_child(_moves)
	_mode = _label("", 13)
	row3.add_child(_mode)

	var right := _panel(Control.PRESET_TOP_RIGHT)
	_metrics = _label("SOLVER\n—", 15)
	_metrics.custom_minimum_size.x = 190
	right.add_child(_metrics)

	_status = _label("", 18, Color.WHITE, 8)
	_status.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.offset_top = -48
	_status.offset_left = -500
	_status.offset_right = 500
	add_child(_status)

<<<<<<< Updated upstream
	_build_level_select()
=======
	var corner := HBoxContainer.new()   # bottom-right: settings + help
	corner.add_theme_constant_override("separation", 10)
	corner.add_child(_button("CÀI ĐẶT", show_settings))
	corner.add_child(_button("HƯỚNG DẪN", show_help))
	add_child(corner)
	corner.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT, Control.PRESET_MODE_MINSIZE, 18)
	corner.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	corner.grow_vertical = Control.GROW_DIRECTION_BEGIN

	_build_level_select()
	_build_help()
	_build_settings()
	_build_loading()


func _process(delta: float) -> void:
	if not _loading.visible:
		return
	_loading_t += delta
	if _loading_frac < 0.0:   # total unknown: sweep back and forth, starting from 0
		_loading_bar.value = (0.5 - cos(_loading_t * 2.6) * 0.5) * 100.0
	else:                     # ease towards the real percentage
		_loading_bar.value = lerpf(_loading_bar.value, _loading_frac * 100.0, 1.0 - exp(-delta * 10.0))
>>>>>>> Stashed changes


# ---- public API --------------------------------------------------------

func set_levels(levels: Array) -> void:
	## levels: Array of {"id", "name", "group"}
	for c in _grid.get_children():
		c.queue_free()
	for i in levels.size():
		var lv: Dictionary = levels[i]
		var color: Color = GROUP_COLORS.get(lv["group"], Color.WHITE)
		var b := Button.new()
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(170, 92)
		b.text = "%02d\n%s\n%s" % [lv["id"], lv["name"], str(lv["group"]).to_upper()]
		b.add_theme_font_size_override("font_size", 15)
		b.add_theme_font_override("font", _font)
		b.add_theme_color_override("font_color", INK)
		b.add_theme_color_override("font_hover_color", INK)
		b.add_theme_color_override("font_pressed_color", INK)
		b.add_theme_stylebox_override("normal", _style(color, 4, true, 6))
		b.add_theme_stylebox_override("hover", _style(color.lightened(0.25), 4, true, 6))
		b.add_theme_stylebox_override("pressed", _style(color.darkened(0.1), 4, true, 1))
		var idx := i
		b.pressed.connect(func() -> void:
			_select.visible = false
			level_selected.emit(idx))
		_grid.add_child(b)


func show_level_select() -> void:
	_select.visible = true


func is_level_select_open() -> bool:
	return _select.visible


<<<<<<< Updated upstream
=======
func show_help() -> void:
	_help.visible = true


func hide_help() -> void:
	_help.visible = false


func is_help_open() -> bool:
	return _help.visible


func show_settings() -> void:
	_settings.visible = true


func hide_settings() -> void:
	_settings.visible = false


func is_settings_open() -> bool:
	return _settings.visible


## Highlight the chosen switch-colour button.
func set_marker_style(style: String) -> void:
	for key in _style_buttons:
		var b: Button = _style_buttons[key]
		b.add_theme_stylebox_override("normal", _style(RED if key == style else CREAM, 4, true, 5))
		b.add_theme_color_override("font_color", Color.WHITE if key == style else INK)


## Waiting board while Python solves (does not block the buttons: R / RESTART
## / LEVELS still work and cancel the solve).
## frac = share of the level's states explored so far (0..1), or -1 if unknown.
func show_loading(title: String, detail: String, frac: float = -1.0) -> void:
	if not _loading.visible or _loading_title.text != title:   # a new solve
		_loading_t = 0.0
		_loading_bar.value = 0.0
	_loading_frac = minf(frac, 1.0)
	_loading_bar.show_percentage = frac >= 0.0
	_loading_title.text = title
	_loading_detail.text = detail
	_loading.visible = true


func hide_loading() -> void:
	_loading.visible = false


>>>>>>> Stashed changes
func set_title(text: String) -> void:
	_title.text = text


func set_moves(n: int) -> void:
	_moves.text = "Moves: %d" % n


func set_mode(online: bool) -> void:
	_mode.text = "● Python server" if online else "○ Offline"
	_mode.add_theme_color_override("font_color", Color("7dffa8") if online else YELLOW)


func set_metrics(algo: String, m: Dictionary) -> void:
	var algo_name := "A*" if algo == "astar" else algo.to_upper()
	_metrics.text = "%s RESULT\nMoves      %d\nExpanded   %d\nTime       %.2f ms\nPeak mem   %.1f KB" % [
		algo_name, int(m.get("length", 0)), int(m.get("expanded", 0)),
		float(m.get("time_ms", 0)), float(m.get("peak_kb", 0))]


func set_status(text: String) -> void:
	_status.text = text


# ---- level select ------------------------------------------------------

func _build_level_select() -> void:
	_select = ColorRect.new()
	(_select as ColorRect).color = Color(0.18, 0.06, 0.28, 0.78)
	_select.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_select.visible = false
	add_child(_select)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_select.add_child(center)
	var panel := PanelContainer.new()
	var ps := _style(PANEL, 8, true, 10)
	ps.set_content_margin_all(28)
	panel.add_theme_stylebox_override("panel", ps)
	center.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 18)
	panel.add_child(v)
	var title := _label("CHỌN MÀN CHƠI", 30, YELLOW, 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(740, 380)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(scroll)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	scroll.add_child(_grid)
	var close := _button("ĐÓNG", func() -> void: _select.visible = false)
	close.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(close)


<<<<<<< Updated upstream
=======
# ---- help & loading boards (wood frame, moss on the broken edges) -------

const WOOD := Color("9a6234")
const WOOD_DARK := Color("4a2a12")
const WOOD_LIGHT := Color("b57a46")
const PAPER := Color("f8ecd0")
const MOSS := [Color("6cc04a"), Color("4fa53a"), Color("8fdc5c")]


## Old wooden sign: jagged planks with chips and cracks, a rough paper
## panel inside. Drawn in code (no image), so it scales and stays sharp.
class WoodFrame extends Control:
	const MARGIN := 22.0

	func _jagged(r: Rect2, step: float, depth: float, rng: RandomNumberGenerator, chips: int) -> PackedVector2Array:
		var pts := PackedVector2Array()
		var corners := [r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)]
		var chip_at := {}
		for k in chips:   # a few deep notches = broken-off pieces
			chip_at[rng.randi() % 40] = true
		var idx := 0
		for e in 4:
			var a: Vector2 = corners[e]
			var b: Vector2 = corners[(e + 1) % 4]
			var n := maxi(2, int(a.distance_to(b) / step))
			var inward := (b - a).normalized().orthogonal()   # points into the rectangle
			for t in n:
				var pnt := a.lerp(b, float(t) / n)
				var d := rng.randf_range(0.0, depth)
				if chip_at.has(idx % 40):
					d = depth * 2.6
				if t == 0:
					d *= 0.4   # keep corners roughly in place
				pts.append(pnt + inward * d)
				idx += 1
		return pts

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 11
		var outer := _jagged(Rect2(Vector2.ZERO, size), 18.0, 5.0, rng, 5)
		draw_colored_polygon(outer, GameUI.WOOD)
		# plank seams and wood grain on the visible border
		var plank := size.y / 3.0
		for k in [1, 2]:
			draw_line(Vector2(4, plank * k), Vector2(MARGIN - 2, plank * k + 2), GameUI.WOOD_DARK, 2.0)
			draw_line(Vector2(size.x - MARGIN + 2, plank * k - 3), Vector2(size.x - 4, plank * k), GameUI.WOOD_DARK, 2.0)
		for k in int(size.x / 26.0):
			var x := 10.0 + k * 26.0 + rng.randf_range(-6, 6)
			var w := rng.randf_range(10, 22)
			draw_line(Vector2(x, 7 + rng.randf_range(0, 6)), Vector2(x + w, 7 + rng.randf_range(0, 6)), GameUI.WOOD_LIGHT, 1.5)
			draw_line(Vector2(x, size.y - 9 - rng.randf_range(0, 6)), Vector2(x + w, size.y - 9 - rng.randf_range(0, 6)), GameUI.WOOD_LIGHT, 1.5)
		# cracks running in from the edges
		for k in 6:
			var on_top := k % 2 == 0
			var x := size.x * rng.randf_range(0.08, 0.92)
			var y := 2.0 if on_top else size.y - 2.0
			var line := PackedVector2Array([Vector2(x, y)])
			for s in 3:
				x += rng.randf_range(-7, 7)
				y += rng.randf_range(4, 7) * (1.0 if on_top else -1.0)
				line.append(Vector2(x, y))
			draw_polyline(line, GameUI.WOOD_DARK, 2.0)
		draw_polyline(outer + PackedVector2Array([outer[0]]), GameUI.WOOD_DARK, 4.0)
		# rough paper panel inside
		var inner := _jagged(Rect2(Vector2(MARGIN, MARGIN), size - Vector2(MARGIN, MARGIN) * 2), 26.0, 2.5, rng, 2)
		draw_colored_polygon(inner, GameUI.PAPER)
		draw_polyline(inner + PackedVector2Array([inner[0]]), Color("6b4420"), 2.5)


## Moss clumps and leaf sprouts on the corners (drawn over the frame).
class Moss extends Control:
	func _leaf(base: Vector2, angle: float, length: float, color: Color) -> void:
		var pts := PackedVector2Array()
		for i in 13:   # almond shape: two arcs from base to tip
			var t := float(i) / 12.0
			pts.append(Vector2(t * length, sin(t * PI) * length * 0.32))
		for i in range(11, 0, -1):
			var t := float(i) / 12.0
			pts.append(Vector2(t * length, -sin(t * PI) * length * 0.32))
		var xf := Transform2D(angle, base)
		draw_colored_polygon(xf * pts, color)
		draw_line(base, xf * Vector2(length * 0.9, 0), color.darkened(0.35), 1.5)

	func _clump(center: Vector2, radius: float, rng: RandomNumberGenerator) -> void:
		for i in 14:
			var off := Vector2(rng.randf_range(-radius, radius), rng.randf_range(-radius * 0.55, radius * 0.55))
			var c: Color = GameUI.MOSS[rng.randi() % GameUI.MOSS.size()]
			draw_circle(center + off, rng.randf_range(radius * 0.25, radius * 0.45), c)
		for i in 6:   # light speckles
			var off := Vector2(rng.randf_range(-radius, radius), rng.randf_range(-radius * 0.5, radius * 0.4))
			draw_circle(center + off, rng.randf_range(1.5, 3.0), Color("c4f08a"))

	func _draw() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		var r := minf(size.y * 0.16, 30.0)
		_clump(Vector2(r * 0.9, r * 0.5), r, rng)                       # top-left
		_clump(Vector2(size.x - r * 0.9, r * 0.5), r, rng)              # top-right
		_clump(Vector2(r * 0.8, size.y - r * 0.45), r * 0.85, rng)      # bottom-left
		_clump(Vector2(size.x - r * 0.8, size.y - r * 0.45), r * 0.85, rng)   # bottom-right
		var leaf := Color("4caf3c")
		_leaf(Vector2(r * 0.6, 0), -2.3, r * 1.3, leaf)
		_leaf(Vector2(r * 1.2, -2), -1.2, r * 1.1, Color("6cc04a"))
		_leaf(Vector2(size.x - r * 0.6, 0), -0.85, r * 1.3, leaf)
		_leaf(Vector2(size.x - r * 1.3, -2), -1.95, r * 1.0, Color("6cc04a"))
		_leaf(Vector2(size.x - r * 0.4, size.y - 4), -0.2, r * 0.9, leaf)
		_leaf(Vector2(r * 0.4, size.y - 4), PI + 0.2, r * 0.9, leaf)


func _wood_board(min_size: Vector2) -> Array:
	## Returns [root, content VBox]. Root is centred on screen.
	var root := CenterContainer.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.visible = false
	add_child(root)
	var frame := PanelContainer.new()   # every child gets the frame's full rect
	frame.custom_minimum_size = min_size
	frame.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	root.add_child(frame)
	var wood := WoodFrame.new()   # first child = drawn behind the content
	wood.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(wood)
	var pad := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, int(WoodFrame.MARGIN) + 18)
	frame.add_child(pad)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 10)
	pad.add_child(v)
	var moss := Moss.new()        # last child = drawn over the edges
	moss.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(moss)
	frame.resized.connect(func() -> void:
		wood.queue_redraw()
		moss.queue_redraw())
	return [root, v]


func _build_help() -> void:
	var parts := _wood_board(Vector2(620, 0))
	_help = parts[0]
	_help.mouse_filter = Control.MOUSE_FILTER_STOP
	var v: VBoxContainer = parts[1]
	var title := _label("HƯỚNG DẪN CHƠI", 26, YELLOW, 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var goal := _label("Mục tiêu: dựng đứng khối trên ô đích tròn.", 16, INK, 0)
	goal.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(goal)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 6)
	v.add_child(grid)
	for row in HELP_LINES:
		grid.add_child(_label(row[0], 16, RED, 0))
		grid.add_child(_label(row[1], 16, INK, 0))
	var ok := _button("ĐÃ HIỂU", hide_help, true)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ok)


func _build_settings() -> void:
	var parts := _wood_board(Vector2(520, 0))
	_settings = parts[0]
	_settings.mouse_filter = Control.MOUSE_FILTER_STOP
	var v: VBoxContainer = parts[1]
	var title := _label("CÀI ĐẶT", 26, YELLOW, 8)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(title)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 12)
	v.add_child(row)
	row.add_child(_label("Màu ô công tắc:", 17, INK, 0))
	for opt in [["dam", "ĐẬM"], ["nhat", "NHẠT"]]:
		var key: String = opt[0]
		var b := _button(opt[1], func() -> void:
			set_marker_style(key)
			marker_style_changed.emit(key))
		_style_buttons[key] = b
		row.add_child(b)
	var note := _label("Đậm: công tắc màu đặc, dễ nhìn. Nhạt: màu phát sáng nhẹ.", 14, Color("7a5a3a"), 0)
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(note)
	var ok := _button("ĐÓNG", hide_settings, true)
	ok.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(ok)


func _build_loading() -> void:
	var parts := _wood_board(Vector2(460, 0))
	_loading = parts[0]
	var v: VBoxContainer = parts[1]
	_loading_title = _label("ĐANG GIẢI", 26, YELLOW, 8)
	_loading_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_loading_title)
	_loading_detail = _label("", 17, INK, 0)
	_loading_detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_child(_loading_detail)
	_loading_bar = ProgressBar.new()
	_loading_bar.show_percentage = false
	_loading_bar.custom_minimum_size = Vector2(0, 26)
	_loading_bar.add_theme_font_override("font", _font)
	_loading_bar.add_theme_font_size_override("font_size", 15)
	_loading_bar.add_theme_color_override("font_color", INK)
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color("e2cfa6")
	bg.set_corner_radius_all(6)
	bg.set_border_width_all(2)
	bg.border_color = Color("6b4420")
	var fill := StyleBoxFlat.new()
	fill.bg_color = MOSS[0]
	fill.set_corner_radius_all(6)
	_loading_bar.add_theme_stylebox_override("background", bg)
	_loading_bar.add_theme_stylebox_override("fill", fill)
	v.add_child(_loading_bar)
	for c in [_loading_title, _loading_detail, _loading_bar, v]:
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE


>>>>>>> Stashed changes
# ---- styling helpers (voxel look: blocky, thick outline, hard shadow) ----

const INK := Color("5a1a10")          # outlines and dark text
const PANEL := Color("ee7a2a")
const CREAM := Color("f6efe6")
const YELLOW := Color("ffd23f")
const RED := Color("e8432e")

var _font: SystemFont = _make_font()


static func _make_font() -> SystemFont:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Segoe UI Black", "Arial Black", "Segoe UI"])
	f.font_weight = 900
	return f


func _style(color: Color, radius: int = 4, border: bool = true, shadow: int = 6) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 7
	s.content_margin_bottom = 7
	if border:
		s.set_border_width_all(3)
		s.border_color = INK
	if shadow > 0:
		s.shadow_color = Color(INK, 0.9)
		s.shadow_size = 1
		s.shadow_offset = Vector2(0, shadow)
	return s


func _panel(preset: Control.LayoutPreset) -> PanelContainer:
	var p := PanelContainer.new()
	var s := _style(PANEL, 6, true, 8)
	s.set_content_margin_all(16)
	p.add_theme_stylebox_override("panel", s)
	add_child(p)
	p.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, 18)
	if preset == Control.PRESET_TOP_RIGHT:
		p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	return p


func _label(text: String, size: int, color: Color = Color.WHITE, outline: int = 6) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", _font)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", outline)
	return l


func _button(text: String, on_press: Callable, accent: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	var base := RED if accent else CREAM
	var fg := Color.WHITE if accent else INK
	b.add_theme_stylebox_override("normal", _style(base, 4, true, 5))
	b.add_theme_stylebox_override("hover", _style(YELLOW if not accent else base.lightened(0.15), 4, true, 5))
	var pressed := _style(base.darkened(0.1), 4, true, 1)
	pressed.content_margin_top = 11
	pressed.content_margin_bottom = 3
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_font_override("font", _font)
	b.add_theme_font_size_override("font_size", 14)
	for k in ["font_color", "font_hover_color", "font_pressed_color"]:
		b.add_theme_color_override(k, fg if k != "font_hover_color" or accent else INK)
	if accent:
		b.add_theme_color_override("font_outline_color", INK)
		b.add_theme_constant_override("outline_size", 4)
	b.pressed.connect(on_press)
	return b