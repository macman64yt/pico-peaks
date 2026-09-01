extends Control

var world: Node

const BAR_W := 620.0
const BAR_H := 84.0
const RANGE := 75.0

var _font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(BAR_W, BAR_H)
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	position = Vector2(-BAR_W * 0.5, 8.0)
	grow_horizontal = Control.GROW_DIRECTION_BOTH
	grow_vertical = Control.GROW_DIRECTION_BEGIN
	_font = get_theme_default_font()


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	if world == null:
		return
	var player: Node3D = world.get("_player")
	if player == null or not is_instance_valid(player):
		return
	var yaw := _player_yaw()
	var bf: float = -rad_to_deg(yaw)
	var cx := size.x * 0.5
	var bar_y := 44.0
	var t := Time.get_ticks_msec() / 1000.0

	draw_rect(Rect2(0.0, bar_y, size.x, 3.0), Color(1, 1, 1, 0.22))
	draw_line(Vector2(cx, bar_y - 2.0), Vector2(cx, bar_y - 16.0), Color(1, 1, 1, 0.95), 2.0)

	for deg in range(-180, 181, 15):
		if absf(deg) > RANGE:
			continue
		var x := cx + deg / RANGE * (size.x * 0.5)
		var major := fposmod(deg, 90.0) == 0.0
		var mid := fposmod(deg, 45.0) == 0.0 and not major
		var h := 16.0 if major else (11.0 if mid else 6.0)
		draw_line(Vector2(x, bar_y), Vector2(x, bar_y - h),
			Color(1, 1, 1, 0.85 if major else (0.5 if mid else 0.28)),
			2.0 if major else 1.0)
		if major:
			var b := int(fposmod(round(bf + deg), 360.0))
			draw_string(_font, Vector2(x - 10.0, bar_y - h - 4.0), _dir_letter(b),
				HORIZONTAL_ALIGNMENT_CENTER, 20.0, 13, Color(1, 1, 1, 0.9))

	var ppos := player.global_position
	var p := Vector2(ppos.x, ppos.z)

	var plant_b: Variant = _nearest_reactor_bearing(p)
	if plant_b != null:
		_draw_marker(plant_b, cx, bar_y, "PLANT", Color(1.0, 0.3, 0.25), t)

	var shrine: Node3D = world.get("_shrine")
	if shrine != null and is_instance_valid(shrine):
		var sp: Vector3 = shrine.global_position
		_draw_marker(_bearing_to(p, Vector2(sp.x, sp.z)), cx, bar_y, "SHRINE", Color(0.65, 0.5, 1.0), t)

	var blackout: bool = world.get("_grid_blackout")
	if blackout:
		var v: Variant = _nearest_village_bearing(p)
		if v != null:
			_draw_marker(v, cx, bar_y, "BLACKOUT", Color(1.0, 0.6, 0.15), t)

	var z: Variant = _zombie_info(p)
	if z != null:
		var col := Color(0.7, 1.0, 0.3) if float(z[2]) > 30.0 else Color(1.0, 0.3, 0.25)
		_draw_marker(float(z[0]), cx, bar_y, "ZOMBIES x%d" % int(z[1]), col, t)

	var day := int(floor(float(world.get("_time_of_day")) / 24.0)) + 1
	draw_string(_font, Vector2(12.0, 22.0), "DAY %d" % day, HORIZONTAL_ALIGNMENT_LEFT, 120.0, 15,
		Color(1, 1, 1, 0.85))
	draw_string(_font, Vector2(size.x - 112.0, 22.0), "COMPASS", HORIZONTAL_ALIGNMENT_LEFT, 100.0, 12,
		Color(1, 1, 1, 0.35))


func _draw_marker(rel: float, cx: float, bar_y: float, label: String, color: Color, t: float) -> void:
	if absf(rel) > RANGE:
		return
	var x := cx + rel / RANGE * (size.x * 0.5)
	var pulse := 0.65 + 0.35 * sin(t * 6.0)
	draw_primitive(
		PackedVector2Array([Vector2(x, bar_y - 30.0), Vector2(x - 7.0, bar_y - 18.0), Vector2(x + 7.0, bar_y - 18.0)]),
		PackedColorArray([color, color, color]),
		PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO]))
	draw_line(Vector2(x, bar_y - 17.0), Vector2(x, bar_y), Color(color.r, color.g, color.b, 0.6), 1.0)
	draw_string(_font, Vector2(x - 40.0, bar_y - 34.0), label, HORIZONTAL_ALIGNMENT_CENTER, 80.0, 13,
		Color(color.r, color.g, color.b, pulse))


func _nearest_reactor_bearing(p: Vector2) -> Variant:
	var best: Vector2 = Vector2.ZERO
	var best_d := INF
	var found := false
	for r in world.get("_reactors"):
		if r == null or not is_instance_valid(r):
			continue
		var pos: Vector3 = (r as Node3D).global_position
		var q := Vector2(pos.x, pos.z)
		var d := p.distance_squared_to(q)
		if d < best_d:
			best_d = d
			best = q
			found = true
	if not found:
		return null
	return _bearing_to(p, best)


func _nearest_village_bearing(p: Vector2) -> Variant:
	var villages: Array = world.get("_villages")
	var best: Vector2 = Vector2.ZERO
	var best_d := INF
	for v in villages:
		var q: Vector2 = v
		var d := p.distance_squared_to(q)
		if d < best_d:
			best_d = d
			best = q
	if best_d == INF:
		return null
	return _bearing_to(p, best)


func _bearing_to(p: Vector2, q: Vector2) -> float:
	var dx := q.x - p.x
	var dz := q.y - p.y
	var world_b := rad_to_deg(atan2(dx, -dz))
	var yaw := _player_yaw()
	var bf: float = -rad_to_deg(yaw)
	return wrapf(world_b - bf, -180.0, 180.0)


func _zombie_info(p: Vector2) -> Variant:
	var best_b := 0.0
	var best_d := INF
	var best_dist := 0.0
	var count := 0
	for z in get_tree().get_nodes_in_group("zombies"):
		if z == null or not is_instance_valid(z):
			continue
		var pos: Vector3 = (z as Node3D).global_position
		var q := Vector2(pos.x, pos.z)
		var d := p.distance_squared_to(q)
		if d < best_d:
			best_d = d
			best_dist = sqrt(d)
			best_b = _bearing_to(p, q)
		if d < 2500.0:
			count += 1
	if best_d == INF or best_dist > 60.0:
		return null
	return [best_b, maxi(count, 1), best_dist]


func _player_yaw() -> float:
	var player: Node3D = world.get("_player")
	if player == null:
		return 0.0
	if bool(player.get("in_boat")):
		var b: Node3D = world.get("_boat")
		if b != null and is_instance_valid(b):
			return b.rotation.y
	if bool(player.get("in_car")):
		var cid := int(player.get("in_car_id"))
		var cars: Array = world.get("_cars_list")
		if cid >= 0 and cid < cars.size() and cars[cid] != null and is_instance_valid(cars[cid]):
			return (cars[cid] as Node3D).rotation.y
	return player.rotation.y


func _dir_letter(b: int) -> String:
	var idx := int(round(fposmod(float(b) / 90.0, 4.0))) % 4
	var letters := ["N", "E", "S", "W"]
	return letters[idx]
