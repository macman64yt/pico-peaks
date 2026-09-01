extends Control

var world: Node

var _log: RichTextLabel
var _console_input: LineEdit
var _panel: Panel
var _open := false
var _lines: Array[String] = []


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("console")

	var panel := Panel.new()
	_panel = panel
	panel.position = Vector2(12.0, 12.0)
	panel.size = Vector2(560.0, 224.0)
	panel.visible = false
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.02, 0.02, 0.05, 0.8)
	sb.border_color = Color(0.3, 0.5, 0.4, 0.9)
	sb.set_border_width_all(1)
	sb.set_content_margin_all(10.0)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)

	_log = RichTextLabel.new()
	_log.set_anchors_preset(Control.PRESET_FULL_RECT)
	_log.offset_left = 10.0
	_log.offset_top = 8.0
	_log.offset_right = -10.0
	_log.offset_bottom = -36.0
	_log.bbcode_enabled = true
	_log.scroll_active = true
	_log.add_theme_font_size_override("normal_font_size", 14)
	_log.add_theme_color_override("default_color", Color(0.75, 1.0, 0.8))
	panel.add_child(_log)

	_console_input = LineEdit.new()
	_console_input.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_console_input.position = Vector2(10.0, -26.0)
	_console_input.size = Vector2(540.0, 30.0)
	_console_input.placeholder_text = "Dev console — type /help   (` opens, Esc closes)"
	_console_input.visible = false
	_console_input.text_submitted.connect(_on_submit)
	panel.add_child(_console_input)

	post_line("Type /help for commands.")


func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_QUOTELEFT and not _open:
			open()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and _open:
			close()
			get_viewport().set_input_as_handled()


func open() -> void:
	_open = true
	_panel.visible = true
	_console_input.visible = true
	_console_input.grab_focus()


func close() -> void:
	_open = false
	_panel.visible = false
	_console_input.visible = false
	_console_input.release_focus()
	_console_input.text = ""


func is_open() -> bool:
	return _open


func post_line(text: String) -> void:
	_lines.append(text)
	if _lines.size() > 40:
		_lines.pop_front()
	_log.text = "\n".join(_lines)


func _on_submit(t: String) -> void:
	t = t.strip_edges()
	if t.is_empty():
		close()
		return
	post_line("> " + t)
	if world and world.has_method("_run_command"):
		var resp: String = world._run_command(t)
		if not resp.is_empty():
			post_line(resp)
	_console_input.text = ""
