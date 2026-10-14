class_name GameUI
extends CanvasLayer
## Glass-style HUD (title, controls, solver buttons, metrics, status) and the
## level-select screen.

signal new_game_pressed
signal restart_pressed
signal level_selected(index: int)
signal solve_pressed(algo: String)

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

	_build_level_select()


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
