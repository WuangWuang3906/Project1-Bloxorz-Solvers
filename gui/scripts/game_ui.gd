class_name GameUI
extends CanvasLayer
## Glass-style HUD: title, controls, solver buttons, metrics, status line.

signal new_game_pressed
signal restart_pressed
signal level_selected(index: int)
signal solve_pressed(algo: String)

const ALGOS := [["BFS", "bfs"], ["DFS", "dfs"], ["UCS", "ucs"], ["A*", "astar"]]

var _title: Label
var _levels: OptionButton
var _moves: Label
var _metrics: Label
var _status: Label


func _ready() -> void:
	var left := _panel(Control.PRESET_TOP_LEFT)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	left.add_child(box)
	_title = _label("BLOXORZ", 22)
	box.add_child(_title)

	var row1 := HBoxContainer.new()
	box.add_child(row1)
	row1.add_child(_button("NEW GAME", func() -> void: new_game_pressed.emit()))
	row1.add_child(_button("RESTART", func() -> void: restart_pressed.emit()))
	_levels = OptionButton.new()
	_levels.focus_mode = Control.FOCUS_NONE
	_levels.add_theme_stylebox_override("normal", _style(Color(1, 1, 1, 0.08), 10))
	_levels.add_theme_stylebox_override("hover", _style(Color(1, 1, 1, 0.16), 10))
	_levels.item_selected.connect(func(i: int) -> void: level_selected.emit(i))
	row1.add_child(_levels)

	var row2 := HBoxContainer.new()
	box.add_child(row2)
	for a in ALGOS:
		var algo: String = a[1]
		var b := _button(a[0], func() -> void: solve_pressed.emit(algo), true)
		row2.add_child(b)
	_moves = _label("Moves: 0", 15)
	box.add_child(_moves)

	var right := _panel(Control.PRESET_TOP_RIGHT)
	_metrics = _label("SOLVER\n—", 15)
	_metrics.custom_minimum_size.x = 190
	right.add_child(_metrics)

	_status = _label("", 17)
	_status.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.offset_top = -48
	_status.offset_left = -400
	_status.offset_right = 400
	add_child(_status)


func set_levels(names: Array, selected: int) -> void:
	_levels.clear()
	for n in names:
		_levels.add_item(n)
	_levels.select(selected)


func select_level(index: int) -> void:
	_levels.select(index)


func set_title(text: String) -> void:
	_title.text = text


func set_moves(n: int) -> void:
	_moves.text = "Moves: %d" % n


func set_metrics(algo: String, m: Dictionary) -> void:
	_metrics.text = "%s RESULT\nMoves      %s\nExpanded   %s\nTime       %s ms\nPeak mem   %s KB" % [
		algo.to_upper(), m.get("length", "-"), m.get("expanded", "-"), m.get("time_ms", "-"), m.get("peak_kb", "-")]


func set_status(text: String) -> void:
	_status.text = text


# ---- styling helpers ---------------------------------------------------

func _style(color: Color, radius: int, border: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	s.set_corner_radius_all(radius)
	s.content_margin_left = 14
	s.content_margin_right = 14
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	if border:
		s.set_border_width_all(1)
		s.border_color = Color(1, 1, 1, 0.18)
	return s


func _panel(preset: Control.LayoutPreset) -> PanelContainer:
	var p := PanelContainer.new()
	var s := _style(Color(0.05, 0.06, 0.13, 0.5), 16, true)
	s.set_content_margin_all(16)
	p.add_theme_stylebox_override("panel", s)
	add_child(p)
	p.set_anchors_and_offsets_preset(preset, Control.PRESET_MODE_MINSIZE, 18)
	if preset == Control.PRESET_TOP_RIGHT:
		p.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	return p


func _label(text: String, size: int) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", Color.WHITE)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.5))
	return l


func _button(text: String, on_press: Callable, accent: bool = false) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	var base := Color(1.0, 0.45, 0.36, 0.95) if accent else Color(1, 1, 1, 0.08)
	b.add_theme_stylebox_override("normal", _style(base, 10))
	b.add_theme_stylebox_override("hover", _style(base.lightened(0.2), 10))
	b.add_theme_stylebox_override("pressed", _style(base.darkened(0.2), 10))
	b.add_theme_font_size_override("font_size", 14)
	b.pressed.connect(on_press)
	return b
