extends Control

signal message_sent(text: String)

var _log: RichTextLabel
var _chat_input: LineEdit
var _panel: PanelContainer
var _open := false
var _lines: Array[String] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_to_group("chat")

	_panel = PanelContainer.new()
	_panel.clip_contents = true
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.03, 0.04, 0.07, 0.55)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(8)
	style.border_color = Color(1, 1, 1, 0.15)
	style.set_border_width_all(1)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.add_child(box)

	_log = RichTextLabel.new()
	_log.bbcode_enabled = true
	_log.scroll_active = true
	_log.scroll_following = true
	_log.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log.add_theme_font_size_override("normal_font_size", 14)
	_log.add_theme_color_override("default_color", Color(1, 1, 1, 0.92))
	_log.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_log.add_theme_constant_override("outline_size", 3)
	box.add_child(_log)

	_chat_input = LineEdit.new()
	_chat_input.placeholder_text = "Chat message...  (T opens, Enter sends, Esc closes)"
	_chat_input.custom_minimum_size = Vector2(480.0, 30.0)
	_chat_input.size_flags_vertical = Control.SIZE_SHRINK_END
	_chat_input.visible = false
	_chat_input.text_submitted.connect(_on_submit)
	box.add_child(_chat_input)

	_layout()
	var vp := get_viewport()
	if vp:
		vp.size_changed.connect(_layout)


func _layout() -> void:
	var vp := get_viewport()
	var vs := vp.get_visible_rect().size if vp else Vector2(1280.0, 720.0)
	_panel.position = Vector2(vs.x - 500.0, vs.y - 140.0)
	_panel.size = Vector2(488.0, 128.0)


func _input(event: InputEvent) -> void:
	if get_tree().paused:
		return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_T and not _open:
			open()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_ESCAPE and _open:
			close()
			get_viewport().set_input_as_handled()


func open() -> void:
	_open = true
	_chat_input.visible = true
	_chat_input.grab_focus()


func close() -> void:
	_open = false
	_chat_input.visible = false
	_chat_input.release_focus()
	_chat_input.text = ""


func is_open() -> bool:
	return _open


func post_line(from: String, text: String) -> void:
	var col := "lightgreen"
	match from.to_lower():
		"you":
			col = "lightblue"
		"system":
			col = "gold"
	_lines.append("[color=%s]%s:[/color] %s" % [col, from, text])
	if _lines.size() > 12:
		_lines.pop_front()
	_log.parse_bbcode("\n".join(_lines) + "\n")


func _on_submit(t: String) -> void:
	t = t.strip_edges()
	if t.is_empty():
		close()
		return
	message_sent.emit(t)
	_chat_input.text = ""
