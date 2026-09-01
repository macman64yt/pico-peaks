extends Control

var _player: Node3D
var _world: Node
var _label: Label
var _visible_flag := false

const VERSION := "1.0.0"


func setup(player: Node3D, world: Node) -> void:
	_player = player
	_world = world
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)
	position = Vector2.ZERO
	_label = Label.new()
	_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_label.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_label.grow_vertical = Control.GROW_DIRECTION_BEGIN
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label.position = Vector2(-580.0, 10.0)
	_label.size = Vector2(568.0, 230.0)
	_label.add_theme_font_size_override("font_size", 13)
	_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)
	visible = false


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		_visible_flag = not _visible_flag
		visible = _visible_flag
		get_viewport().set_input_as_handled()


func _process(_delta: float) -> void:
	if not _visible_flag:
		return
	var fps := Engine.get_frames_per_second()
	var pos: Vector3 = _player.global_position
	var yaw := _player.rotation.y
	var facing := _facing(yaw)
	var h := _height_at(pos)
	var biome := _biome(h)
	var mem := OS.get_static_memory_usage() / 1048576.0
	var mem_peak := OS.get_static_memory_peak_usage() / 1048576.0
	var chunk := Vector2i(int(floor(pos.x / 16.0)), int(floor(pos.z / 16.0)))
	var time_ms := 1000.0 / fps if fps > 0 else 0.0
	_label.text = "Pico Peaks %s\nFPS: %d (%.1f ms)\nXYZ: %.2f / %.2f / %.2f\nFacing: %s (yaw %.1f deg)\nPitch: %.1f deg\nChunk: %d %d\nBiome: %s\nHeight: %.2f m\nMemory: %.1f MiB (peak %.1f MiB)\n" % [
		VERSION, fps, time_ms,
		pos.x, pos.y, pos.z,
		facing, rad_to_deg(yaw),
		rad_to_deg(_pitch()),
		chunk.x, chunk.y,
		biome, h,
		mem, mem_peak,
	]


func _height_at(pos: Vector3) -> float:
	return _world._height_at(pos.x, pos.z) if _world and _world.has_method("_height_at") else 0.0


func _pitch() -> float:
	if _player and _player.get_node_or_null("CameraRig"):
		return _player.get_node("CameraRig").rotation.x
	return 0.0


func _facing(yaw: float) -> String:
	var dirs := ["South (+Z)", "West (-X)", "North (-Z)", "East (+X)"]
	var deg := fmod(rad_to_deg(yaw), 360.0)
	if deg < 0.0:
		deg += 360.0
	return dirs[int(round(deg / 90.0)) % 4]


func _biome(h: float) -> String:
	if h < 0.3:
		return "Ocean"
	elif h < 1.5:
		return "Beach"
	elif h < 12.0:
		return "Grasslands"
	elif h < 27.0:
		return "Highlands"
	return "Peaks"
