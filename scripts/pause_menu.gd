extends Control

signal resume_requested
signal quit_requested
signal save_and_quit_requested
signal grass_density_changed(density: float)
signal mangohud_toggled(on: bool)
signal video_settings_changed(width: int, height: int, mode: String)
signal quality_changed(quality: int)
signal ui_scale_changed(scale: float)

var _env: Environment
var _cam_attr: CameraAttributesPractical
var _player: CharacterBody3D
var world: Node
var _dim: ColorRect
var _panel: PanelContainer
var _settings_panel: Control

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


func setup(env: Environment, cam_attr: CameraAttributesPractical, player: CharacterBody3D) -> void:
	_env = env
	_cam_attr = cam_attr
	_player = player


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()
	get_viewport().size_changed.connect(_relayout)
	_relayout()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if world != null and bool(world.get("_reactor_panel_open")):
			return
		if world != null and bool(world.get("_phone_open")):
			return
		if visible:
			resume_requested.emit()
		else:
			open()
		get_viewport().set_input_as_handled()


func open() -> void:
	visible = true
	_relayout()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	visible = false


func _relayout() -> void:
	var vs := get_viewport().get_visible_rect().size
	_panel.anchor_left = 0.0
	_panel.anchor_top = 0.0
	_panel.anchor_right = 0.0
	_panel.anchor_bottom = 0.0
	_panel.offset_left = 0.0
	_panel.offset_top = 0.0
	_panel.offset_right = 0.0
	_panel.offset_bottom = 0.0
	_panel.reset_size()
	var psize := _panel.get_combined_minimum_size()
	_panel.position = ((vs - psize) / 2.0).floor()


func _build_ui() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0.0, 0.0, 0.0, 0.45)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.09, 0.11, 0.94)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(24)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 12)
	_panel.add_child(root)

	var title := Label.new()
	title.text = "PAUSED"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	root.add_child(title)

	var resume := _make_button("Resume")
	resume.pressed.connect(_on_resume)
	root.add_child(resume)

	var save_quit := _make_button("Save & Quit to Menu")
	save_quit.pressed.connect(_on_save_and_quit)
	root.add_child(save_quit)

	var quit := _make_button("Quit to Desktop")
	quit.pressed.connect(_on_quit)
	root.add_child(quit)

	var sep := HSeparator.new()
	root.add_child(sep)

	_settings_panel = preload("res://scripts/settings_panel.gd").new()
	_settings_panel.setup(_env, _cam_attr, _player, false)
	_settings_panel.grass_density_changed.connect(func(v: float) -> void: grass_density_changed.emit(v))
	_settings_panel.mangohud_toggled.connect(func(on: bool) -> void: mangohud_toggled.emit(on))
	_settings_panel.video_settings_changed.connect(func(w: int, h: int, m: String) -> void: video_settings_changed.emit(w, h, m))
	_settings_panel.quality_changed.connect(func(q: int) -> void: quality_changed.emit(q))
	_settings_panel.ui_scale_changed.connect(func(s: float) -> void: ui_scale_changed.emit(s))
	root.add_child(_settings_panel)


func set_mangohud(on: bool) -> void:
	if _settings_panel and _settings_panel.has_method("set_mangohud"):
		_settings_panel.set_mangohud(on)


func set_quality(q: int) -> void:
	if _settings_panel and _settings_panel.has_method("set_quality"):
		_settings_panel.set_quality(q)


func set_ui_scale(v: float) -> void:
	if _settings_panel and _settings_panel.has_method("set_ui_scale"):
		_settings_panel.set_ui_scale(v)


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


func _make_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0.0, 36.0)
	return btn


func _on_resume() -> void:
	resume_requested.emit()


func _on_save_and_quit() -> void:
	save_and_quit_requested.emit()


func _on_quit() -> void:
	quit_requested.emit()
