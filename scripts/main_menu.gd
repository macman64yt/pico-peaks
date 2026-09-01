extends Control

signal start_world(name: String, seed: int, season: String)
signal quit_requested
signal grass_density_changed(density: float)
signal mangohud_toggled(on: bool)
signal video_settings_changed(width: int, height: int, mode: String)
signal quality_changed(quality: int)
signal ui_scale_changed(scale: float)

var _env: Environment
var _cam_attr: CameraAttributesPractical
var _player: CharacterBody3D
var _dim: ColorRect
var _panel: PanelContainer
var _root: VBoxContainer
var _views: Dictionary = {}
var _current_view := "main"
var _settings_panel: Control
var _worlds_cfg := ConfigFile.new()
var _worlds_path := "user://worlds.cfg"
var _worlds_box: VBoxContainer
var _name_field: LineEdit
var _seed_field: SpinBox
var _season_sel: OptionButton
var _join_name: LineEdit
var _join_host: LineEdit
var _join_port: SpinBox
var _quality := 3


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
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if _current_view != "main":
			_go_back()
		get_viewport().set_input_as_handled()


func open() -> void:
	visible = true
	_show_view("main")
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


func set_mangohud(on: bool) -> void:
	if _settings_panel and _settings_panel.has_method("set_mangohud"):
		_settings_panel.set_mangohud(on)


func set_quality(q: int) -> void:
	_quality = q
	if _settings_panel and _settings_panel.has_method("set_quality"):
		_settings_panel.set_quality(q)


func set_ui_scale(v: float) -> void:
	if _settings_panel and _settings_panel.has_method("set_ui_scale"):
		_settings_panel.set_ui_scale(v)


# ---------------------------------------------------------------- views

func _show_view(view: String) -> void:
	for key in _views:
		_views[key].visible = (key == view)
	_current_view = view
	if view == "worlds":
		_rebuild_worlds()
	_relayout()


func _go_back() -> void:
	match _current_view:
		"play", "servers", "settings":
			_show_view("main")
		"worlds":
			_show_view("play")
		"newworld":
			_show_view("worlds")
		_:
			_show_view("main")


# ---------------------------------------------------------------- worlds persistence

func _load_worlds() -> Array[Dictionary]:
	_worlds_cfg.load(_worlds_path)
	var out: Array[Dictionary] = []
	for section in _worlds_cfg.get_sections():
		out.append({
			"name": section,
			"seed": int(_worlds_cfg.get_value(section, "seed", 2024)),
			"season": String(_worlds_cfg.get_value(section, "season", "summer")),
		})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a["name"]).to_lower() < String(b["name"]).to_lower())
	if out.is_empty():
		_save_world("Default", 2024, "summer")
		out.append({"name": "Default", "seed": 2024, "season": "summer"})
	return out


func _save_world(name: String, seed: int, season: String) -> void:
	_worlds_cfg.load(_worlds_path)
	_worlds_cfg.set_value(name, "seed", seed)
	_worlds_cfg.set_value(name, "season", season)
	_worlds_cfg.save(_worlds_path)


func _delete_world(name: String) -> void:
	_worlds_cfg.load(_worlds_path)
	_worlds_cfg.erase_section(name)
	if _worlds_cfg.get_sections().is_empty():
		_worlds_cfg.set_value("Default", "seed", 2024)
		_worlds_cfg.set_value("Default", "season", "summer")
	_worlds_cfg.save(_worlds_path)


# ---------------------------------------------------------------- ui

func _build_ui() -> void:
	_dim = ColorRect.new()
	_dim.color = Color(0.0, 0.0, 0.0, 0.55)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_dim)

	_panel = PanelContainer.new()
	_panel.set_anchors_preset(Control.PRESET_CENTER)
	_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.07, 0.08, 0.10, 0.96)
	style.set_corner_radius_all(14)
	style.set_content_margin_all(28)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)

	_root = VBoxContainer.new()
	_root.add_theme_constant_override("separation", 12)
	_panel.add_child(_root)

	_views["main"] = _build_main_view()
	_views["play"] = _build_play_view()
	_views["worlds"] = _build_worlds_view()
	_views["newworld"] = _build_new_world_view()
	_views["servers"] = _build_servers_view()
	_views["settings"] = _build_settings_view()
	for key in _views:
		_views[key].visible = false
		_root.add_child(_views[key])


func _heading(text: String) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color(0.9, 0.95, 1.0))
	return label


func _make_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0.0, 40.0)
	return btn


func _build_main_view() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)

	var title := Label.new()
	title.text = "PICO PEAKS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 44)
	title.add_theme_color_override("font_color", Color(0.95, 0.97, 1.0))
	box.add_child(title)

	var sub := Label.new()
	sub.text = "PICO PEAKS 1.0.0 — every texture is procedural"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 14)
	sub.add_theme_color_override("font_color", Color(0.65, 0.7, 0.78))
	box.add_child(sub)

	box.add_child(HSeparator.new())

	var play := _make_button("Play")
	play.pressed.connect(func() -> void: _show_view("play"))
	box.add_child(play)

	var settings := _make_button("Settings")
	settings.pressed.connect(func() -> void: _show_view("settings"))
	box.add_child(settings)

	var quit := _make_button("Quit")
	quit.pressed.connect(func() -> void: quit_requested.emit())
	box.add_child(quit)

	return box


func _build_play_view() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.add_child(_heading("PLAY"))

	var worlds := _make_button("Worlds")
	worlds.pressed.connect(func() -> void: _show_view("worlds"))
	box.add_child(worlds)

	var servers := _make_button("Servers")
	servers.pressed.connect(func() -> void: _show_view("servers"))
	box.add_child(servers)

	var back := _make_button("Back")
	back.pressed.connect(func() -> void: _go_back())
	box.add_child(back)

	return box


func _build_worlds_view() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.add_child(_heading("WORLDS"))

	_worlds_box = VBoxContainer.new()
	_worlds_box.add_theme_constant_override("separation", 6)
	box.add_child(_worlds_box)

	var new_world := _make_button("New World")
	new_world.pressed.connect(func() -> void: _show_view("newworld"))
	box.add_child(new_world)

	var back := _make_button("Back")
	back.pressed.connect(func() -> void: _go_back())
	box.add_child(back)

	return box


func _rebuild_worlds() -> void:
	for child in _worlds_box.get_children():
		child.queue_free()
	for world in _load_worlds():
		_worlds_box.add_child(_world_row(world))


func _world_row(world: Dictionary) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	var label := Label.new()
	label.text = "%s — seed %d (%s)" % [world["name"], int(world["seed"]), String(world["season"]).capitalize()]
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_font_size_override("font_size", 16)
	row.add_child(label)

	var play := _make_button("Play")
	play.custom_minimum_size = Vector2(100.0, 36.0)
	play.pressed.connect(func() -> void:
		start_world.emit(world["name"], int(world["seed"]), String(world["season"])))
	row.add_child(play)

	var del := _make_button("Delete")
	del.custom_minimum_size = Vector2(100.0, 36.0)
	del.pressed.connect(func() -> void: _delete_world(world["name"]))
	row.add_child(del)

	return row


func _build_new_world_view() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.add_child(_heading("NEW WORLD"))

	var name_label := Label.new()
	name_label.text = "World name"
	name_label.add_theme_font_size_override("font_size", 14)
	box.add_child(name_label)

	_name_field = LineEdit.new()
	_name_field.placeholder_text = "My World"
	box.add_child(_name_field)

	var seed_label := Label.new()
	seed_label.text = "Seed (optional — random if blank)"
	seed_label.add_theme_font_size_override("font_size", 14)
	box.add_child(seed_label)

	_seed_field = SpinBox.new()
	_seed_field.min_value = 0
	_seed_field.max_value = 2147483647
	_seed_field.step = 1
	_seed_field.rounded = true
	_seed_field.value = _rand_seed()
	box.add_child(_seed_field)

	var randomize := _make_button("Randomize Seed")
	randomize.pressed.connect(func() -> void: _seed_field.value = _rand_seed())
	box.add_child(randomize)

	var season_label := Label.new()
	season_label.text = "Season"
	season_label.add_theme_font_size_override("font_size", 14)
	box.add_child(season_label)

	_season_sel = OptionButton.new()
	_season_sel.add_item("Spring", 0)
	_season_sel.add_item("Summer", 1)
	_season_sel.add_item("Winter", 2)
	_season_sel.select(1)
	box.add_child(_season_sel)

	var create := _make_button("Create & Play")
	create.pressed.connect(_on_create_world)
	box.add_child(create)

	var back := _make_button("Back")
	back.pressed.connect(func() -> void: _go_back())
	box.add_child(back)

	return box


func _rand_seed() -> int:
	return randi() % 2147483647


func _on_create_world() -> void:
	var name := _name_field.text.strip_edges()
	if name.is_empty():
		name = "New World"
	var base := name
	var n := 1
	var existing := {}
	for w in _load_worlds():
		existing[String(w["name"]).to_lower()] = true
	while existing.has(name.to_lower()):
		n += 1
		name = "%s %d" % [base, n]
	var seed := int(_seed_field.value)
	var seasons := ["spring", "summer", "winter"]
	var season: String = seasons[_season_sel.selected] if _season_sel else "summer"
	_save_world(name, seed, season)
	start_world.emit(name, seed, season)


func _build_servers_view() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.add_child(_heading("MULTIPLAYER"))

	var note := Label.new()
	note.text = "Join a Pico Peaks dedicated server running on your LAN.\nStart one with the Server Launcher app, or on another machine."
	note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	note.add_theme_font_size_override("font_size", 14)
	note.add_theme_color_override("font_color", Color(0.65, 0.7, 0.78))
	box.add_child(note)

	var name_label := Label.new()
	name_label.text = "Your name"
	name_label.add_theme_font_size_override("font_size", 14)
	box.add_child(name_label)

	_join_name = LineEdit.new()
	_join_name.placeholder_text = "Player"
	box.add_child(_join_name)

	var host_label := Label.new()
	host_label.text = "Server address"
	host_label.add_theme_font_size_override("font_size", 14)
	box.add_child(host_label)

	_join_host = LineEdit.new()
	_join_host.placeholder_text = "127.0.0.1"
	_join_host.text = "127.0.0.1"
	box.add_child(_join_host)

	var port_label := Label.new()
	port_label.text = "Port"
	port_label.add_theme_font_size_override("font_size", 14)
	box.add_child(port_label)

	_join_port = SpinBox.new()
	_join_port.min_value = 1
	_join_port.max_value = 65535
	_join_port.step = 1
	_join_port.rounded = true
	_join_port.value = 25565
	box.add_child(_join_port)

	var connect := _make_button("Connect")
	connect.pressed.connect(_join_server)
	box.add_child(connect)

	var back := _make_button("Back")
	back.pressed.connect(func() -> void: _go_back())
	box.add_child(back)

	return box


func _join_server() -> void:
	var cfg := ConfigFile.new()
	cfg.load("user://settings.cfg")
	var name := _join_name.text.strip_edges()
	if name.is_empty():
		name = "Player"
	cfg.set_value("net", "player_name", name)
	cfg.save("user://settings.cfg")
	Net.pending_join_host = _join_host.text.strip_edges()
	if Net.pending_join_host.is_empty():
		Net.pending_join_host = "127.0.0.1"
	Net.pending_join_port = int(_join_port.value)
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")


func _build_settings_view() -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.add_child(_heading("SETTINGS"))

	_settings_panel = preload("res://scripts/settings_panel.gd").new()
	_settings_panel.setup(_env, _cam_attr, _player, false)
	_settings_panel.set_quality(_quality)
	_settings_panel.grass_density_changed.connect(func(v: float) -> void: grass_density_changed.emit(v))
	_settings_panel.mangohud_toggled.connect(func(on: bool) -> void: mangohud_toggled.emit(on))
	_settings_panel.video_settings_changed.connect(func(w: int, h: int, m: String) -> void: video_settings_changed.emit(w, h, m))
	_settings_panel.quality_changed.connect(func(q: int) -> void: quality_changed.emit(q))
	_settings_panel.ui_scale_changed.connect(func(s: float) -> void: ui_scale_changed.emit(s))
	box.add_child(_settings_panel)

	var back := _make_button("Back")
	back.pressed.connect(func() -> void: _go_back())
	box.add_child(back)

	return box
