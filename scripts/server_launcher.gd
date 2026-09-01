extends Control

const PID_FILE := "/tmp/opencode/server.pid"
const LOG_FILE := "/tmp/opencode/server.log"

var _ram: SpinBox
var _port: SpinBox
var _max: SpinBox
var _seed: SpinBox
var _name: LineEdit
var _status: Label
var _log_view: TextEdit
var _start_btn: Button
var _stop_btn: Button
var _server_pid := -1
var _log_pos := 0
var _running := false
var _marked_ready := false


func _ready() -> void:
	_build_ui()
	_refresh_pid_from_file()


func _process(_delta: float) -> void:
	if not _running:
		return
	_tail_log()
	var srv := _read_pid_file()
	if srv > 0:
		_server_pid = srv
	if _server_pid > 0 and not _proc_alive(_server_pid):
		if _log_view.text.contains("Couldn't create an ENet host"):
			_set_stopped("Port %d is already in use. Stop the other server first." % int(_port.value))
		else:
			_set_stopped("Server stopped unexpectedly.")
		return
	if not _marked_ready and _log_view.text.contains("DEDICATED SERVER ready"):
		_marked_ready = true
		_status.text = "Server: running (pid %d)" % _server_pid
		_status.add_theme_color_override("font_color", Color(0.3, 0.8, 0.4))


func _proc_alive(pid: int) -> bool:
	return DirAccess.dir_exists_absolute("/proc/%d" % pid)


func _build_ui() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 24)
	margin.add_theme_constant_override("margin_right", 24)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = "Pico Peaks — Dedicated Server"
	title.add_theme_font_size_override("font_size", 30)
	vbox.add_child(title)

	var hint := Label.new()
	hint.text = "Start a headless multiplayer world. Other players connect to your IP:port."
	hint.modulate = Color(0.75, 0.78, 0.85)
	vbox.add_child(hint)

	_status = Label.new()
	_status.text = "Server: stopped"
	_status.add_theme_color_override("font_color", Color(0.75, 0.3, 0.3))
	vbox.add_child(_status)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 8)
	vbox.add_child(grid)

	_ram = _make_spin(256, 16384, 2048, 1)
	_ram.tooltip_text = "Memory budget (MB). Scales world density: trees, NPCs, cars, zombies."
	grid.add_child(_make_label("Memory budget (MB)"))
	grid.add_child(_ram)

	_port = _make_spin(1024, 65535, 25565, 1)
	grid.add_child(_make_label("Port"))
	grid.add_child(_port)

	_max = _make_spin(1, 64, 8, 1)
	grid.add_child(_make_label("Max players"))
	grid.add_child(_max)

	_seed = _make_spin(0, 2147483647, 2024, 1)
	grid.add_child(_make_label("World seed"))
	grid.add_child(_seed)

	_name = LineEdit.new()
	_name.text = "Pico Peaks Server"
	_name.custom_minimum_size = Vector2(320, 0)
	grid.add_child(_make_label("Server name"))
	grid.add_child(_name)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	vbox.add_child(row)

	_start_btn = Button.new()
	_start_btn.text = "Start Server"
	_start_btn.pressed.connect(_start_server)
	row.add_child(_start_btn)

	_stop_btn = Button.new()
	_stop_btn.text = "Stop Server"
	_stop_btn.pressed.connect(_stop_server)
	_stop_btn.disabled = true
	row.add_child(_stop_btn)

	var quit_btn := Button.new()
	quit_btn.text = "Quit"
	quit_btn.pressed.connect(func() -> void: get_tree().quit())
	row.add_child(quit_btn)

	var log_label := Label.new()
	log_label.text = "Server log:"
	log_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(log_label)

	_log_view = TextEdit.new()
	_log_view.editable = false
	_log_view.custom_minimum_size = Vector2(0, 300)
	_log_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_log_view)

	var bin := OS.get_executable_path()
	var info := Label.new()
	info.text = "Binary: %s\nLog: %s" % [bin, LOG_FILE]
	info.modulate = Color(0.6, 0.62, 0.68)
	info.add_theme_font_size_override("font_size", 12)
	vbox.add_child(info)


func _make_label(text: String) -> Label:
	var l := Label.new()
	l.text = text
	l.custom_minimum_size = Vector2(180, 0)
	return l


func _make_spin(min: int, max: int, value: int, step: int) -> SpinBox:
	var s := SpinBox.new()
	s.min_value = min
	s.max_value = max
	s.value = value
	s.step = step
	s.custom_minimum_size = Vector2(200, 0)
	return s


func _find_wrapper() -> String:
	var candidates := [
		OS.get_executable_path().get_base_dir().path_join("server_wrapper.sh"),
		ProjectSettings.globalize_path("res://scripts/server_wrapper.sh"),
	]
	for c in candidates:
		if FileAccess.file_exists(c):
			return c
	return candidates[0]


func _start_server() -> void:
	if _running:
		return
	var args := PackedStringArray([
		"--port", str(int(_port.value)),
		"--max-players", str(int(_max.value)),
		"--seed", str(int(_seed.value)),
		"--ram-mb", str(int(_ram.value)),
		"--name", _name.text,
	])
	var wrapper := _find_wrapper()
	var err := OS.create_process(wrapper, args)
	if err < 0:
		_status.text = "Failed to launch server (error %d)." % err
		return
	_server_pid = err
	_running = true
	_marked_ready = false
	_start_btn.disabled = true
	_stop_btn.disabled = false
	_status.text = "Server starting (pid %d)..." % _server_pid
	_status.add_theme_color_override("font_color", Color(0.9, 0.75, 0.3))
	_log_pos = 0
	_log_view.text = ""
	await get_tree().create_timer(1.5).timeout
	if _running:
		_tail_log()


func _set_stopped(msg: String) -> void:
	_running = false
	_server_pid = -1
	_marked_ready = false
	_start_btn.disabled = false
	_stop_btn.disabled = true
	_status.text = msg
	_status.add_theme_color_override("font_color", Color(0.75, 0.3, 0.3))


func _stop_server() -> void:
	if not _running and _server_pid < 0:
		return
	var pid := _read_pid_file()
	if pid < 0:
		pid = _server_pid
	if pid > 0:
		OS.kill(pid)
	_set_stopped("Server: stopped")


func _tail_log() -> void:
	var f := FileAccess.open(LOG_FILE, FileAccess.READ)
	if f == null:
		return
	var text := f.get_as_text()
	if text.length() < _log_pos:
		_log_pos = 0
	if text.length() > _log_pos:
		_log_view.text += text.substr(_log_pos)
		_log_view.set_caret_line(_log_view.get_line_count() - 1)
	_log_pos = text.length()


func _refresh_pid_from_file() -> void:
	var pid := _read_pid_file()
	if pid > 0 and _proc_alive(pid):
		_server_pid = pid
		_running = true
		_marked_ready = false
		_start_btn.disabled = true
		_stop_btn.disabled = false
		_status.text = "Server: running (pid %d)" % pid
		_status.add_theme_color_override("font_color", Color(0.3, 0.8, 0.4))
		_log_pos = 0
		_log_view.text = ""
		_tail_log()


func _read_pid_file() -> int:
	var f := FileAccess.open(PID_FILE, FileAccess.READ)
	if f == null:
		return -1
	var line := f.get_line().strip_edges()
	if line.is_valid_int():
		return int(line)
	return -1
