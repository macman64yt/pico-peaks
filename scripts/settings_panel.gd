extends TabContainer

signal grass_density_changed(density: float)
signal mangohud_toggled(on: bool)
signal video_settings_changed(width: int, height: int, mode: String)
signal quality_changed(quality: int)
signal ui_scale_changed(scale: float)

var _env: Environment
var _cam_attr: CameraAttributesPractical
var _player: CharacterBody3D
var _mangohud_on := false
var _hud_btn: CheckButton
var _res_sel: OptionButton
var _mode_sel: OptionButton
var _quality_sel: OptionButton
var _quality := 2
var _video_width := 1920
var _video_height := 1080
var _video_mode := "windowed"
var _ui_scale := 1.0

var _quality_names := ["Low", "Medium", "High", "Ultra"]

var _resolutions := [
	Vector2i(1280, 720),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160),
]

var _toggles := [
	["SDFGI", "sdfgi"],
	["Volumetric Fog", "volumetric"],
	["Glow", "glow"],
	["Screen-space Reflections", "ssr"],
	["Ambient Occlusion", "ssao"],
	["Depth of Field", "dof"],
	["Auto Exposure", "autoexp"],
	["Distance Fog", "fog"],
]


func setup(env: Environment, cam_attr: CameraAttributesPractical, player: CharacterBody3D, mangohud_on: bool) -> void:
	_env = env
	_cam_attr = cam_attr
	_player = player
	_mangohud_on = mangohud_on
	if _hud_btn:
		_hud_btn.button_pressed = _mangohud_on


func _ready() -> void:
	custom_minimum_size = Vector2(520.0, 380.0)
	_build_controls_tab()
	_build_graphics_tab()


func _build_controls_tab() -> void:
	var controls := VBoxContainer.new()
	controls.add_theme_constant_override("separation", 10)
	add_child(controls)
	set_tab_title(controls.get_index(), "Controls")

	var info := Label.new()
	info.text = "WASD  move     SHIFT  sprint     SPACE  jump\nV  toggle camera     F  flashlight\nESC  pause     Click  lock mouse"
	info.add_theme_font_size_override("font_size", 15)
	info.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95))
	controls.add_child(info)

	var sens_box := HBoxContainer.new()
	controls.add_child(sens_box)
	var sens_label := Label.new()
	sens_label.text = "Mouse sensitivity"
	sens_label.custom_minimum_size = Vector2(200.0, 0.0)
	sens_box.add_child(sens_label)
	var sens_slider := HSlider.new()
	sens_slider.min_value = 0.2
	sens_slider.max_value = 2.5
	sens_slider.step = 0.05
	sens_slider.value = 1.0
	sens_slider.custom_minimum_size = Vector2(220.0, 0.0)
	sens_slider.value_changed.connect(_on_sens_changed)
	sens_box.add_child(sens_slider)
	var sens_val := Label.new()
	sens_val.text = "100%"
	sens_val.custom_minimum_size = Vector2(50.0, 0.0)
	sens_box.add_child(sens_val)
	sens_slider.value_changed.connect(func(v: float) -> void: sens_val.text = "%d%%" % int(round(v * 100.0)))

	var invert_box := HBoxContainer.new()
	controls.add_child(invert_box)
	var invert_label := Label.new()
	invert_label.text = "Invert mouse Y"
	invert_label.custom_minimum_size = Vector2(200.0, 0.0)
	invert_box.add_child(invert_label)
	var invert_btn := CheckButton.new()
	invert_btn.toggled.connect(_on_invert_toggled)
	invert_box.add_child(invert_btn)

	var ui_scale_box := HBoxContainer.new()
	controls.add_child(ui_scale_box)
	var ui_scale_label := Label.new()
	ui_scale_label.text = "UI Scale"
	ui_scale_label.custom_minimum_size = Vector2(200.0, 0.0)
	ui_scale_box.add_child(ui_scale_label)
	var ui_scale_slider := HSlider.new()
	ui_scale_slider.min_value = 0.7
	ui_scale_slider.max_value = 1.8
	ui_scale_slider.step = 0.05
	ui_scale_slider.value = _ui_scale
	ui_scale_slider.custom_minimum_size = Vector2(220.0, 0.0)
	ui_scale_slider.value_changed.connect(_on_ui_scale_changed)
	ui_scale_box.add_child(ui_scale_slider)
	var ui_scale_val := Label.new()
	ui_scale_val.text = "%d%%" % int(round(_ui_scale * 100.0))
	ui_scale_val.custom_minimum_size = Vector2(50.0, 0.0)
	ui_scale_box.add_child(ui_scale_val)
	ui_scale_slider.value_changed.connect(func(v: float) -> void: ui_scale_val.text = "%d%%" % int(round(v * 100.0)))


func _build_graphics_tab() -> void:
	var graphics := VBoxContainer.new()
	graphics.add_theme_constant_override("separation", 8)
	add_child(graphics)
	set_tab_title(graphics.get_index(), "Graphics")

	var quality_box := HBoxContainer.new()
	graphics.add_child(quality_box)
	var quality_label := Label.new()
	quality_label.text = "Quality Preset"
	quality_label.custom_minimum_size = Vector2(200.0, 0.0)
	quality_box.add_child(quality_label)
	_quality_sel = OptionButton.new()
	_quality_sel.custom_minimum_size = Vector2(220.0, 0.0)
	for qn in _quality_names:
		_quality_sel.add_item(qn)
	_quality_sel.selected = clampi(_quality, 0, _quality_names.size() - 1)
	_quality_sel.item_selected.connect(_on_quality_selected)
	quality_box.add_child(_quality_sel)

	var quality_note := Label.new()
	quality_note.text = "Preset controls resolution scale, MSAA, shadows, SDFGI, fog,\nand tree/rock/grass density. Individual toggles below override."
	quality_note.add_theme_font_size_override("font_size", 11)
	quality_note.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	graphics.add_child(quality_note)

	for t in _toggles:
		var row := HBoxContainer.new()
		graphics.add_child(row)
		var cb := CheckButton.new()
		cb.toggled.connect(_on_toggle.bind(t[1]))
		cb.button_pressed = _toggle_value(t[1])
		row.add_child(cb)
		var lbl := Label.new()
		lbl.text = t[0]
		row.add_child(lbl)

	var grass_box := HBoxContainer.new()
	graphics.add_child(grass_box)
	var grass_label := Label.new()
	grass_label.text = "Grass Density"
	grass_label.custom_minimum_size = Vector2(200.0, 0.0)
	grass_box.add_child(grass_label)
	var grass_slider := HSlider.new()
	grass_slider.min_value = 0.0
	grass_slider.max_value = 2.0
	grass_slider.step = 0.05
	grass_slider.value = 1.0
	grass_slider.custom_minimum_size = Vector2(220.0, 0.0)
	grass_box.add_child(grass_slider)
	var grass_val := Label.new()
	grass_val.text = "100%"
	grass_val.custom_minimum_size = Vector2(50.0, 0.0)
	grass_box.add_child(grass_val)
	grass_slider.value_changed.connect(func(v: float) -> void:
		grass_val.text = "%d%%" % int(round(v * 100.0))
	)
	grass_slider.value_changed.connect(_on_grass_changed)

	var hud_box := HBoxContainer.new()
	graphics.add_child(hud_box)
	var hud_btn := CheckButton.new()
	hud_btn.button_pressed = _mangohud_on
	hud_btn.toggled.connect(_on_mangohud_toggled)
	hud_box.add_child(hud_btn)
	_hud_btn = hud_btn
	var hud_label := Label.new()
	hud_label.text = "MangoHUD overlay"
	hud_box.add_child(hud_label)
	var hud_note := Label.new()
	hud_note.text = "Applies when launched from the Pico Peaks shortcut (restart to apply)."
	hud_note.add_theme_font_size_override("font_size", 11)
	hud_note.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7))
	graphics.add_child(hud_note)

	var sep := HSeparator.new()
	graphics.add_child(sep)

	var res_box := HBoxContainer.new()
	graphics.add_child(res_box)
	var res_label := Label.new()
	res_label.text = "Resolution"
	res_label.custom_minimum_size = Vector2(200.0, 0.0)
	res_box.add_child(res_label)
	_res_sel = OptionButton.new()
	_res_sel.custom_minimum_size = Vector2(220.0, 0.0)
	_res_sel.item_selected.connect(_on_resolution_selected)
	res_box.add_child(_res_sel)
	_populate_resolutions()

	var mode_box := HBoxContainer.new()
	graphics.add_child(mode_box)
	var mode_label := Label.new()
	mode_label.text = "Window Mode"
	mode_label.custom_minimum_size = Vector2(200.0, 0.0)
	mode_box.add_child(mode_label)
	_mode_sel = OptionButton.new()
	_mode_sel.custom_minimum_size = Vector2(220.0, 0.0)
	_mode_sel.add_item("Windowed")
	_mode_sel.add_item("Fullscreen")
	_mode_sel.add_item("Borderless Fullscreen")
	_mode_sel.item_selected.connect(_on_mode_selected)
	mode_box.add_child(_mode_sel)
	_video_mode = _current_mode()
	match _video_mode:
		"fullscreen":
			_mode_sel.selected = 1
		"borderless":
			_mode_sel.selected = 2
		_:
			_mode_sel.selected = 0


func _populate_resolutions() -> void:
	var cur := Vector2i(_video_width, _video_height)
	if DisplayServer.get_name() != "headless":
		cur = DisplayServer.window_get_size()
	_video_width = cur.x
	_video_height = cur.y
	var present := _resolutions.has(cur)
	if not present:
		_resolutions.append(cur)
	for i in _resolutions.size():
		_res_sel.add_item("%d x %d" % [_resolutions[i].x, _resolutions[i].y])
		if _resolutions[i] == cur:
			_res_sel.selected = i


func _current_mode() -> String:
	if DisplayServer.get_name() == "headless":
		return "windowed"
	if DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_BORDERLESS):
		return "borderless"
	var mode := DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN or mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		return "fullscreen"
	return "windowed"


func _on_resolution_selected(idx: int) -> void:
	if idx < 0 or idx >= _resolutions.size():
		return
	_video_width = _resolutions[idx].x
	_video_height = _resolutions[idx].y
	video_settings_changed.emit(_video_width, _video_height, _video_mode)


func _on_mode_selected(idx: int) -> void:
	match idx:
		1:
			_video_mode = "fullscreen"
		2:
			_video_mode = "borderless"
		_:
			_video_mode = "windowed"
	video_settings_changed.emit(_video_width, _video_height, _video_mode)


func _toggle_value(which: String) -> bool:
	if _env == null:
		return false
	match which:
		"sdfgi":
			return _env.sdfgi_enabled
		"volumetric":
			return _env.volumetric_fog_enabled
		"glow":
			return _env.glow_enabled
		"ssr":
			return _env.ssr_enabled
		"ssao":
			return _env.ssao_enabled
		"dof":
			return _cam_attr != null and _cam_attr.dof_blur_far_enabled
		"autoexp":
			return _cam_attr != null and _cam_attr.auto_exposure_enabled
		"fog":
			return _env.fog_enabled
	return false


func _on_toggle(on: bool, which: String) -> void:
	if _env == null:
		return
	match which:
		"sdfgi":
			_env.sdfgi_enabled = on
		"volumetric":
			_env.volumetric_fog_enabled = on
		"glow":
			_env.glow_enabled = on
		"ssr":
			_env.ssr_enabled = on
		"ssao":
			_env.ssao_enabled = on
		"dof":
			if _cam_attr:
				_cam_attr.dof_blur_far_enabled = on
		"autoexp":
			if _cam_attr:
				_cam_attr.auto_exposure_enabled = on
		"fog":
			_env.fog_enabled = on


func _on_sens_changed(v: float) -> void:
	if _player:
		_player.mouse_sens = 0.0021 * v


func _on_invert_toggled(on: bool) -> void:
	if _player:
		_player.invert_y = on


func _on_grass_changed(v: float) -> void:
	grass_density_changed.emit(v)


func _on_quality_selected(idx: int) -> void:
	_quality = clampi(idx, 0, _quality_names.size() - 1)
	quality_changed.emit(_quality)


func set_quality(q: int) -> void:
	_quality = clampi(q, 0, _quality_names.size() - 1)
	if _quality_sel:
		_quality_sel.selected = _quality


func _on_mangohud_toggled(on: bool) -> void:
	_mangohud_on = on
	mangohud_toggled.emit(on)


func get_mangohud() -> bool:
	return _mangohud_on


func set_mangohud(on: bool) -> void:
	_mangohud_on = on


func _on_ui_scale_changed(v: float) -> void:
	ui_scale_changed.emit(v)


func set_ui_scale(v: float) -> void:
	_ui_scale = v
