extends CanvasLayer

const WEATHER_NAMES := ["CLEAR", "CLOUDY", "RAIN", "STORM"]
const REACTOR_TYPE_NAMES := ["Experimental", "PWR", "Fast Breeder"]
const TASKS := [
	["reach_plant", "Reach the nuclear plant"],
	["grid_powered", "Power the grid"],
	["cool", "Keep all reactors under 860 C"],
	["storm", "Survive a thunderstorm"],
	["refuel", "Refuel a reactor"],
	["upgrade", "Upgrade a reactor"],
	["car", "Drive a car"],
	["sleep", "Sleep through the night"],
	["fish", "Catch a fish at the dock"],
	["spring", "Relax in the hot spring"],
	["garden", "Watch the gardens ripen"],
	["boat", "Row out on the lake"],
	["shop", "Trade a fish at the market"],
	["shrine", "Receive the east shrine's blessing"],
	["koi", "Catch the rare golden koi"],
	["wolf", "Defeat a hungry wolf"],
	["meteor", "Witness a meteor crash"],
	["bunker", "Find the hidden bunker"],
	["bike", "Ride a dirt bike"],
	["crop", "Harvest a crop"],
]

var world: Node

var _open := false
var _root: Control
var _dim: ColorRect
var _screen: Control
var _screens := {}
var _labels := {}
var _status_time: Label
var _status_weather: Label
var _status_battery: Label
var _last_news_n := -1


func _ready() -> void:
	layer = 30
	_build()


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.visible = false
	add_child(_root)

	_dim = ColorRect.new()
	_dim.color = Color(0.0, 0.0, 0.0, 0.5)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	panel.custom_minimum_size = Vector2(380.0, 600.0)
	var bezel := StyleBoxFlat.new()
	bezel.bg_color = Color(0.02, 0.03, 0.04, 0.99)
	bezel.set_corner_radius_all(28)
	bezel.set_content_margin_all(16)
	bezel.set_border_width_all(3)
	bezel.border_color = Color(0.16, 0.18, 0.22)
	panel.add_theme_stylebox_override("panel", bezel)
	_root.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 8)
	panel.add_child(root)

	var status := HBoxContainer.new()
	status.add_theme_constant_override("separation", 4)
	root.add_child(status)
	_status_time = _label("", 13, Color(0.9, 0.95, 1.0, 0.9))
	_status_time.custom_minimum_size = Vector2(90.0, 0.0)
	status.add_child(_status_time)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status.add_child(spacer)
	_status_weather = _label("", 13, Color(0.7, 0.9, 1.0, 0.9))
	status.add_child(_status_weather)
	_status_battery = _label("BAT 100%", 13, Color(0.6, 1.0, 0.6, 0.9))
	status.add_child(_status_battery)

	var notch := ColorRect.new()
	notch.color = Color(0.08, 0.09, 0.11)
	notch.custom_minimum_size = Vector2(110.0, 14.0)
	notch.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	root.add_child(notch)

	_screen = Control.new()
	_screen.custom_minimum_size = Vector2(340.0, 470.0)
	root.add_child(_screen)

	var home_bar := Button.new()
	home_bar.custom_minimum_size = Vector2(60.0, 14.0)
	home_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	home_bar.flat = true
	var pill := StyleBoxFlat.new()
	pill.bg_color = Color(0.9, 0.92, 1.0, 0.9)
	pill.set_corner_radius_all(7)
	home_bar.add_theme_stylebox_override("normal", pill)
	home_bar.add_theme_stylebox_override("hover", pill)
	home_bar.add_theme_stylebox_override("pressed", pill)
	home_bar.tooltip_text = "Home (close phone)"
	home_bar.pressed.connect(func() -> void: close())
	root.add_child(home_bar)

	_build_home()
	_build_map()
	_build_weather()
	_build_rad()
	_build_news()
	_build_grid()
	_build_tasks()
	_build_system()


func _build_home() -> void:
	var page := VBoxContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.add_child(page)
	_screens["home"] = page
	var title := _label("PHONE", 22, Color(0.8, 0.9, 1.0))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(title)
	var sub := _label("Pico Peaks OS", 13, Color(0.5, 0.6, 0.7))
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(sub)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(grid)
	grid.add_child(_tile("WEATHER", Color(0.2, 0.5, 0.9), func() -> void: _show("weather")))
	grid.add_child(_tile("MAP", Color(0.25, 0.75, 0.8), func() -> void: _show("map")))
	grid.add_child(_tile("RADIATION", Color(0.2, 0.8, 0.4), func() -> void: _show("rad")))
	grid.add_child(_tile("NEWS", Color(0.95, 0.6, 0.2), func() -> void: _show("news")))
	grid.add_child(_tile("POWER GRID", Color(0.9, 0.3, 0.3), func() -> void: _show("grid")))
	grid.add_child(_tile("TASKS", Color(0.3, 0.9, 0.7), func() -> void: _show("tasks")))
	grid.add_child(_tile("SYSTEM", Color(0.55, 0.5, 0.9), func() -> void: _show("system")))


func _build_map() -> void:
	var page := _page("map", "MAP", Color(0.25, 0.75, 0.8))
	var view := preload("res://scripts/phone_map.gd").new()
	view.phone = self
	view.custom_minimum_size = Vector2(0.0, 340.0)
	view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(view)
	page.add_child(_label("V = village   R = reactor   green dot = charging   white = you", 11, Color(0.5, 0.6, 0.7)))


func _build_weather() -> void:
	var page := _page("weather", "WEATHER", Color(0.2, 0.5, 0.9))
	page.add_child(_make_row("Current", "_weather_now"))
	page.add_child(_make_row("Temperature", "_weather_temp"))
	page.add_child(_make_row("Wind", "_weather_wind"))
	page.add_child(_make_row("Rain", "_weather_rain"))
	page.add_child(_make_row("Visibility", "_weather_vis"))
	page.add_child(HSeparator.new())
	page.add_child(_label("6-HOUR FORECAST", 13, Color(0.6, 0.7, 0.8)))
	page.add_child(_label("", 14, Color(0.9, 0.95, 1.0), "_weather_forecast"))


func _build_rad() -> void:
	var page := _page("rad", "RADIATION", Color(0.2, 0.8, 0.4))
	page.add_child(_make_row("Ambient here", "_rad_here"))
	page.add_child(_make_row("Protection", "_rad_hazmat"))
	page.add_child(HSeparator.new())
	page.add_child(_label("FALLOUT ZONES", 13, Color(0.6, 0.8, 0.7)))
	page.add_child(_label("", 14, Color(0.9, 0.95, 1.0), "_rad_zones"))


func _build_news() -> void:
	var page := _page("news", "NEWS", Color(0.95, 0.6, 0.2))
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	page.add_child(scroll)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(vbox)
	page.set_meta("news_box", vbox)


func _build_grid() -> void:
	var page := _page("grid", "POWER GRID", Color(0.9, 0.3, 0.3))
	page.add_child(_make_row("Demand", "_grid_demand"))
	page.add_child(_make_row("Supply", "_grid_supply"))
	page.add_child(_make_row("Status", "_grid_status"))
	page.add_child(_make_row("Wind farm", "_grid_wind"))
	page.add_child(HSeparator.new())
	page.add_child(_label("REACTORS", 13, Color(0.6, 0.8, 0.8)))
	page.add_child(_label("", 14, Color(0.9, 0.95, 1.0), "_grid_reactors"))


func _build_tasks() -> void:
	var page := _page("tasks", "TASKS", Color(0.3, 0.9, 0.7))
	var done := 0
	for t in TASKS:
		if bool(world.get("_tasks")[t[0]]):
			done += 1
	page.add_child(_make_row("Progress", "_task_progress"))
	page.add_child(HSeparator.new())
	for t in TASKS:
		page.add_child(_make_row(str(t[1]), "_task_" + str(t[0])))


func _build_system() -> void:
	var page := _page("system", "SYSTEM", Color(0.55, 0.5, 0.9))
	page.add_child(_make_row("Time", "_sys_time"))
	page.add_child(_make_row("Day", "_sys_day"))
	page.add_child(_make_row("World seed", "_sys_seed"))
	page.add_child(_make_row("Version", "_sys_ver"))
	page.add_child(HSeparator.new())
	page.add_child(_label("CONTROLS", 13, Color(0.7, 0.7, 0.85)))
	page.add_child(_label("", 13, Color(0.75, 0.8, 0.9), "_sys_controls"))


func _page(key: String, title: String, accent: Color) -> VBoxContainer:
	var page := VBoxContainer.new()
	page.set_anchors_preset(Control.PRESET_FULL_RECT)
	_screen.add_child(page)
	_screens[key] = page
	var t := _label(title, 20, accent)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	page.add_child(t)
	var back := Button.new()
	back.text = "< HOME"
	back.custom_minimum_size = Vector2(0.0, 30.0)
	back.pressed.connect(func() -> void: _show("home"))
	page.add_child(back)
	page.add_child(HSeparator.new())
	return page


func _show(key: String) -> void:
	for k in _screens:
		_screens[k].visible = (k == key)
	if key == "news":
		_last_news_n = -1
	_refresh()


func open() -> void:
	if world == null or _open:
		return
	if float(world.get("_phone_battery")) <= 0.0:
		if world.has_method("_post_chat"):
			world._post_chat("Phone", "Battery is dead. Leave the phone closed to recharge.")
		return
	if bool(world.get("_reactor_panel_open")):
		return
	_open = true
	world.set("_phone_open", true)
	var p: Node3D = world.get("_player")
	if p != null:
		p.set("_freeze", true)
	_root.visible = true
	_show("home")
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func close() -> void:
	if not _open:
		return
	_open = false
	world.set("_phone_open", false)
	var p: Node3D = world.get("_player")
	if p != null:
		p.set("_freeze", false)
	_root.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _process(_delta: float) -> void:
	if _open:
		_refresh()


func _refresh() -> void:
	if world == null:
		return
	var tod := fmod(float(world.get("_time_of_day")), 24.0)
	var hh := int(floor(tod))
	var mm := int(floor(fmod(tod, 1.0) * 60.0))
	if _status_time:
		_status_time.text = "%02d:%02d" % [hh, mm]
	var wth := int(world.get("_weather"))
	if _status_weather:
		_status_weather.text = WEATHER_NAMES[wth]
	if _status_battery:
		var pb := float(world.get("_phone_battery"))
		_status_battery.text = "BAT %d%%" % int(pb * 100.0)

	if _screens.has("weather") and _screens["weather"].visible:
		_refresh_weather(wth)
	if _screens.has("rad") and _screens["rad"].visible:
		_refresh_rad()
	if _screens.has("news") and _screens["news"].visible:
		_refresh_news()
	if _screens.has("grid") and _screens["grid"].visible:
		_refresh_grid()
	if _screens.has("tasks") and _screens["tasks"].visible:
		_refresh_tasks()
	if _screens.has("system") and _screens["system"].visible:
		_refresh_system()


func _refresh_weather(wth: int) -> void:
	var elev := 60.0 * cos(TAU * (float(world.get("_time_of_day")) - 12.0) / 24.0)
	var k := clampf(sin(deg_to_rad(elev)) * 3.0 + 0.15, 0.0, 1.0)
	var rain := float(world.get("_rain_density"))
	var temp := 16.0 * k + 3.0 * (1.0 - k) - rain * 5.0
	_set_label("_weather_now", WEATHER_NAMES[wth] + ("  (STORM WARNING)" if wth >= 3 else ""))
	_set_label("_weather_temp", "%.1f C   feels like %.1f C" % [temp, temp - wind_chill()])
	_set_label("_weather_wind", "%d%%  (%d kW/m2)" % [int(float(world.get("_wind_speed")) * 100.0), int(float(world.get("_wind_speed")) * 420.0)])
	_set_label("_weather_rain", ("HEAVY" if wth >= 3 else ("RAINING" if wth >= 2 else "none")))
	_set_label("_weather_vis", "%dm" % (int(2600.0 - rain * 2100.0)))
	var seed_i := int(world.get("_world_seed"))
	var day := int(floor(float(world.get("_time_of_day")) / 24.0))
	var fc := ""
	for i in 3:
		var idx := absi(seed_i + day * 7 + i * 13) % WEATHER_NAMES.size()
		fc += "+%dH: %s\n" % [(i + 1) * 6, WEATHER_NAMES[idx]]
	_set_label("_weather_forecast", fc.strip_edges())


func _refresh_rad() -> void:
	var p: Node3D = world.get("_player")
	var here := 0.0
	var zones := ""
	var reactors: Array = world.get("_reactors")
	var found := 0
	if p != null:
		for r in reactors:
			if r == null or not is_instance_valid(r) or not bool(r.get("exploded")):
				continue
			var d := p.global_position.distance_to((r as Node3D).global_position)
			here = maxf(here, 1.0 - d / 260.0)
			zones += "REACTOR %d   %dm   %d%%\n" % [int(r.get("plant_idx")) + 1, int(d), int((1.0 - d / 260.0) * 100.0)]
			found += 1
	if found == 0:
		zones = "No fallout detected.\nCore scans are clean."
	_set_label("_rad_here", "%d%%" % int(here * 100.0))
	_set_label("_rad_zones", zones.strip_edges())
	var hazmat := p != null and bool(p.get("hazmat"))
	_set_label("_rad_hazmat", ("HAZMAT SUIT ACTIVE (50%% exposure)" if hazmat else "NONE — suit halves exposure"))


func _refresh_news() -> void:
	var log: Array = world.get("_news_log")
	if log.size() == _last_news_n:
		return
	_last_news_n = log.size()
	var vbox: VBoxContainer = _screens["news"].get_meta("news_box")
	for child in vbox.get_children():
		child.free()
	if log.is_empty():
		vbox.add_child(_label("No dispatches yet.", 14, Color(0.7, 0.75, 0.8)))
		return
	var n := int(min(log.size(), 30))
	for i in range(n):
		var entry: Dictionary = log[log.size() - 1 - i]
		var line := _label("%s  %s" % [str(entry.get("t", "--:--")), str(entry.get("m", ""))], 13, Color(0.9, 0.92, 1.0))
		line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		vbox.add_child(line)
		var sep := HSeparator.new()
		sep.modulate.a = 0.3
		vbox.add_child(sep)


func _refresh_grid() -> void:
	var g: Array = world.call("grid_demand") if world.has_method("grid_demand") else [0.0, 0.0, "OFFLINE", false]
	var demand := float(g[0])
	var supply := float(g[1])
	_set_label("_grid_demand", "%d MW%s" % [int(demand), "  (night surge)" if _is_night() else "  (day)"])
	_set_label("_grid_supply", "%d MW" % int(supply))
	_set_label("_grid_status", str(g[2]) + ("  — BLACKOUT" if bool(g[3]) else ""))
	var wind := float(world.call("_wind_mw")) if world.has_method("_wind_mw") else 0.0
	var ws := float(world.get("_wind_speed"))
	_set_label("_grid_wind", "%d MW  (%d turbines @ %d%% wind%s)" % [int(wind), world.get("_turbines").size(), int(ws * 100.0), "  FURLED" if ws > 0.55 else ""])
	var txt := ""
	for r in world.get("_reactors"):
		if r == null or not is_instance_valid(r):
			continue
		var type_i := int(r.get("reactor_type"))
		var type_name: String = REACTOR_TYPE_NAMES[type_i] if type_i < REACTOR_TYPE_NAMES.size() else "?"
		if bool(r.get("exploded")):
			txt += "R%d  %s  DESTROYED\n" % [int(r.get("plant_idx")) + 1, type_name]
			continue
		var status := "OK"
		var t := float(r.get("temp"))
		if t > 1050.0:
			status = "MELTDOWN"
		elif t > 860.0:
			status = "CRITICAL"
		elif t > 700.0:
			status = "HOT"
		txt += "R%d  %s  %dMW  %dC  FUEL %d%%  WATER %d%%  DMG %d%%  %s\n" % [
			int(r.get("plant_idx")) + 1, type_name, int(float(r.get("power01")) * 1000.0),
			int(t), int(float(r.get("fuel")) * 100.0), int(float(r.get("water")) * 100.0),
			int(float(r.get("damage"))), status]
	_set_label("_grid_reactors", txt.strip_edges())


func _refresh_tasks() -> void:
	var tasks: Dictionary = world.get("_tasks")
	var done := 0
	for t in TASKS:
		if bool(tasks.get(str(t[0]), false)):
			done += 1
	_set_label("_task_progress", "%d / %d" % [done, TASKS.size()])
	for t in TASKS:
		var k := "_task_" + str(t[0])
		var is_done: bool = bool(tasks.get(str(t[0]), false))
		if _labels.has(k):
			_labels[k].text = "DONE" if is_done else "TODO"
			_labels[k].add_theme_color_override("font_color",
				Color(0.5, 1.0, 0.6) if is_done else Color(0.55, 0.6, 0.7))


func _refresh_system() -> void:
	var tod := fmod(float(world.get("_time_of_day")), 24.0)
	_set_label("_sys_time", "%02d:%02d" % [int(floor(tod)), int(floor(fmod(tod, 1.0) * 60.0))])
	_set_label("_sys_day", "Day %d" % (int(floor(float(world.get("_time_of_day")) / 24.0)) + 1))
	_set_label("_sys_seed", "%d" % int(world.get("_world_seed")))
	_set_label("_sys_ver", "Pico Peaks 1.0.0 — every texture is procedural")
	_set_label("_sys_controls", "WASD move · SHIFT sprint/turbo · SPACE jump\nLMB shoot · R reload · F flashlight\nV camera · P phone · T chat · E interact\nC fish (in boat) · M radio mute · ESC pause")


func _is_night() -> bool:
	return _is_night_at(float(world.get("_time_of_day")))


func _is_night_at(tod: float) -> bool:
	var t := fmod(tod, 24.0)
	return t >= 18.0 or t < 6.0


func wind_chill() -> float:
	return float(world.get("_wind_speed")) * 3.0


func _set_label(key: String, text: String) -> void:
	if _labels.has(key):
		_labels[key].text = text


func _make_row(name: String, key: String) -> Control:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var name_l := _label(name, 13, Color(0.55, 0.65, 0.75))
	name_l.custom_minimum_size = Vector2(150.0, 0.0)
	name_l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	row.add_child(name_l)
	var val := _label("", 14, Color(0.9, 0.95, 1.0))
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(val)
	_labels[key] = val
	return row


func _tile(text: String, accent: Color, cb: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(150.0, 130.0)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.06, 0.08, 0.10)
	normal.set_corner_radius_all(16)
	normal.set_border_width_all(2)
	normal.border_color = accent
	normal.content_margin_top = 40.0
	var hover := normal.duplicate()
	hover.bg_color = accent.darkened(0.35)
	btn.add_theme_stylebox_override("normal", normal)
	btn.add_theme_stylebox_override("hover", hover)
	btn.add_theme_stylebox_override("pressed", hover)
	btn.add_theme_stylebox_override("focus", normal)
	btn.add_theme_font_size_override("font_size", 15)
	btn.add_theme_color_override("font_color", accent)
	btn.pressed.connect(cb)
	return btn


func _label(text: String, size: int, color: Color, key: String = "") -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	if key != "":
		_labels[key] = l
	return l
