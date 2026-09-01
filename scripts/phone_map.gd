extends Control

var phone: Node

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var world = phone.get("world")
	if world == null:
		return
	var half := 1024.0
	var area := size - Vector2(28.0, 28.0)
	var center := size * 0.5
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.05, 0.06), true)
	draw_rect(Rect2(center - area * 0.5, area), Color(0.07, 0.11, 0.12), true)
	var gs := 8
	for i in gs:
		var t := float(i + 1) / float(gs + 1)
		var x := center.x - area.x * 0.5 + area.x * t
		draw_line(Vector2(x, center.y - area.y * 0.5), Vector2(x, center.y + area.y * 0.5), Color(0.13, 0.19, 0.21), 1.0)
		var y := center.y - area.y * 0.5 + area.y * t
		draw_line(Vector2(center.x - area.x * 0.5, y), Vector2(center.x + area.x * 0.5, y), Color(0.13, 0.19, 0.21), 1.0)
	var rivers: Array = world.get("_rivers")
	for rv in rivers:
		_draw_path(rv, center, area, half, Color(0.16, 0.4, 0.78), 2.0)
	var highways: Array = world.get("_highways")
	for rw in highways:
		_draw_path(rw, center, area, half, Color(0.46, 0.44, 0.42), 3.0)
	var villages: Array = world.get("_villages")
	for i in villages.size():
		var v := villages[i] as Vector2
		var col := Color(0.95, 0.8, 0.5) if i == 0 else Color(0.6, 0.75, 0.85)
		var s := _mp(v, center, area, half)
		draw_circle(s, 5.0, col)
		if i < 6:
			draw_string(ThemeDB.fallback_font, s + Vector2(7.0, -3.0), "V%d" % (i + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
	var reactors: Array = world.get("_reactors")
	for r in reactors:
		if r == null or not is_instance_valid(r):
			continue
		var pos: Vector3 = (r as Node3D).global_position
		var s := _mp(Vector2(pos.x, pos.z), center, area, half)
		var exploded := bool(r.get("exploded"))
		var col := Color(1.0, 0.25, 0.2) if exploded else Color(0.35, 0.95, 0.45)
		draw_circle(s, 5.0, col)
		var idx := int(r.get("plant_idx"))
		if idx < 6:
			draw_string(ThemeDB.fallback_font, s + Vector2(7.0, -3.0), "R%d" % (idx + 1), HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
	var chargers: Array = world.get("_chargers")
	for c in chargers:
		if c == null or not is_instance_valid(c):
			continue
		var cpos: Vector3 = (c as Node3D).global_position
		draw_circle(_mp(Vector2(cpos.x, cpos.z), center, area, half), 2.5, Color(0.25, 0.9, 0.8))
	var turbines: Array = world.get("_turbines")
	for t in turbines:
		if t == null or not is_instance_valid(t):
			continue
		var tpos: Vector3 = (t as Node3D).global_position
		draw_circle(_mp(Vector2(tpos.x, tpos.z), center, area, half), 2.0, Color(0.75, 0.78, 0.82))
	var p: Node3D = world.get("_player")
	if p != null:
		var sp := _mp(Vector2(p.global_position.x, p.global_position.z), center, area, half)
		draw_circle(sp, 7.0, Color(0.0, 0.0, 0.0, 0.55))
		var yaw := p.rotation.y
		var d := Vector2(sin(yaw), -cos(yaw))
		draw_colored_polygon(PackedVector2Array([sp + d * 11.0, sp + Vector2(-4.5, 4.5), sp + Vector2(4.5, 4.5)]), Color(1.0, 1.0, 1.0))


func _mp(p: Vector2, center: Vector2, area: Vector2, half: float) -> Vector2:
	return center + Vector2(p.x / half * area.x * 0.5, -p.y / half * area.y * 0.5)


func _draw_path(pts: Array, center: Vector2, area: Vector2, half: float, col: Color, width: float) -> void:
	if pts.size() < 2:
		return
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		draw_line(_mp(a, center, area, half), _mp(b, center, area, half), col, width)
