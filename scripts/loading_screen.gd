extends CanvasLayer

var _bar: ProgressBar
var _status: Label


func _init() -> void:
	layer = 100


func build() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.04, 0.055, 0.08)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(bg)

	var title := Label.new()
	title.text = "PICO PEAKS"
	title.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	title.position = Vector2(-140.0, -100.0)
	title.size = Vector2(280.0, 44.0)
	title.grow_horizontal = Control.GROW_DIRECTION_BOTH
	title.grow_vertical = Control.GROW_DIRECTION_BOTH
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.72, 0.95, 0.88))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("outline_size", 6)
	add_child(title)

	_bar = ProgressBar.new()
	_bar.max_value = 100.0
	_bar.value = 0.0
	_bar.show_percentage = false
	_bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_bar.position = Vector2(-180.0, -26.0)
	_bar.size = Vector2(360.0, 14.0)
	_bar.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color(0, 0, 0, 0.6)
	bg_style.set_corner_radius_all(6)
	_bar.add_theme_stylebox_override("background", bg_style)
	var fg_style := StyleBoxFlat.new()
	fg_style.bg_color = Color(0.3, 0.9, 0.75)
	fg_style.set_corner_radius_all(6)
	_bar.add_theme_stylebox_override("fill", fg_style)
	add_child(_bar)

	_status = Label.new()
	_status.text = ""
	_status.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_status.position = Vector2(-180.0, -2.0)
	_status.size = Vector2(360.0, 26.0)
	_status.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.add_theme_font_size_override("font_size", 15)
	_status.add_theme_color_override("font_color", Color(1, 1, 1, 0.85))
	_status.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.7))
	_status.add_theme_constant_override("outline_size", 4)
	add_child(_status)


func set_progress(frac: float, text: String) -> void:
	if _bar == null:
		return
	_bar.value = clampf(frac, 0.0, 1.0) * 100.0
	_status.text = text


func finish() -> void:
	queue_free()
