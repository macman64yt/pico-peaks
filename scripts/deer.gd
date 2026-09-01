extends Node3D

var world: Node

var _home := Vector3.ZERO
var _target := Vector3.ZERO
var _pause := 0.0
var _walk_phase := 0.0
var _body: Node3D
var _head: Node3D
var _bolting := false
var _bolt_until := 0.0
var _graze_t := 0.0

func _ready() -> void:
	_home = position
	_build_body()
	_pause = randf_range(0.5, 4.0)
	_pick_target()

func _build_body() -> void:
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.66, 0.5, 0.32)
	body_mat.roughness = 0.85
	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.45, 0.33, 0.2)
	dark_mat.roughness = 0.85
	var flank_mat := StandardMaterial3D.new()
	flank_mat.albedo_color = Color(0.8, 0.72, 0.6)
	flank_mat.roughness = 0.85

	_body = Node3D.new()
	add_child(_body)
	var torso := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(0.34, 0.3, 0.62)
	torso.mesh = tm
	torso.material_override = body_mat
	torso.position = Vector3(0.0, 0.42, 0.0)
	_body.add_child(torso)
	var flank := MeshInstance3D.new()
	var fm := BoxMesh.new()
	fm.size = Vector3(0.32, 0.24, 0.16)
	flank.mesh = fm
	flank.material_override = flank_mat
	flank.position = Vector3(0.0, 0.42, -0.22)
	_body.add_child(flank)
	_head = Node3D.new()
	_head.position = Vector3(0.0, 0.52, 0.3)
	_body.add_child(_head)
	var neck := MeshInstance3D.new()
	var nm := BoxMesh.new()
	nm.size = Vector3(0.14, 0.3, 0.14)
	neck.mesh = nm
	neck.material_override = body_mat
	neck.position = Vector3(0.0, 0.1, 0.0)
	_head.add_child(neck)
	var skull := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.11
	sm.height = 0.22
	skull.mesh = sm
	skull.material_override = body_mat
	skull.position = Vector3(0.0, 0.24, 0.1)
	_head.add_child(skull)
	for ex in [-0.05, 0.05]:
		var antler_mat := StandardMaterial3D.new()
		antler_mat.albedo_color = Color(0.5, 0.42, 0.3)
		var ant := MeshInstance3D.new()
		var am := CylinderMesh.new()
		am.top_radius = 0.01
		am.bottom_radius = 0.02
		am.height = 0.2
		ant.mesh = am
		ant.material_override = antler_mat
		ant.position = Vector3(ex, 0.38, 0.08)
		ant.rotation_degrees = Vector3(-18.0, 0.0, ex * 14.0)
		_head.add_child(ant)
	for lz in [0.22, -0.2]:
		for side in [-0.17, 0.17]:
			var leg := MeshInstance3D.new()
			var lm := BoxMesh.new()
			lm.size = Vector3(0.06, 0.5, 0.06)
			leg.mesh = lm
			leg.material_override = dark_mat
			leg.position = Vector3(side, 0.28, lz)
			_body.add_child(leg)
	var tail := MeshInstance3D.new()
	var tail_mat := StandardMaterial3D.new()
	tail_mat.albedo_color = Color(0.95, 0.93, 0.85)
	var tm2 := BoxMesh.new()
	tm2.size = Vector3(0.1, 0.14, 0.05)
	tail.mesh = tm2
	tail.material_override = tail_mat
	tail.position = Vector3(0.0, 0.52, -0.32)
	_body.add_child(tail)

func _height_at(x: float, z: float) -> float:
	if world and world.has_method("_height_at"):
		return world._height_at(x, z)
	return 0.0

func _storm() -> bool:
	return world != null and int(world.get("_weather")) >= 3

func _zombie_near() -> bool:
	for z in get_tree().get_nodes_in_group("zombies"):
		if global_position.distance_to((z as Node3D).global_position) < 22.0:
			return true
	return false

func _physics_process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var danger := false
	var pl: Node3D = null
	if world != null and world.has_method("_ai_target"):
		pl = world._ai_target(self)
		if pl and global_position.distance_to((pl as Node3D).global_position) < 18.0:
			danger = true
	if _storm() or _zombie_near():
		danger = true
	if danger and not _bolting:
		_bolting = true
		_bolt_until = t + 6.0
		var away := global_position - (pl.global_position if pl else _home)
		away.y = 0.0
		if away.length() < 0.01:
			away = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
		_target = global_position + away.normalized() * 70.0
		_pause = 0.0
	if _bolting and t > _bolt_until:
		_bolting = false
		_pause = randf_range(4.0, 9.0)
		_target = _home

	if _pause > 0.0:
		_pause -= delta
		_body.position.y = 0.05 + absf(sin(t * 3.0)) * 0.03
		_head.rotation.x = sin(t * 0.7) * 0.04
		_graze_t += delta
		if fmod(_graze_t, 7.0) < 1.6:
			_head.rotation.x = lerpf(_head.rotation.x, 0.55, clampf(delta * 4.0, 0.0, 1.0))
		return

	var to := _target - position
	to.y = 0.0
	if to.length() < 1.2:
		if _bolting:
			_bolting = false
			_pause = randf_range(5.0, 10.0)
		else:
			_pause = randf_range(2.0, 6.0)
			_pick_target()
		return
	var speed := 8.5 if _bolting else 2.2
	var dir := to.normalized()
	position.x += dir.x * speed * delta
	position.z += dir.z * speed * delta
	var h := _height_at(position.x, position.z)
	if h < 0.6:
		_pick_target()
		return
	position.y = h + 0.08
	rotation.y = atan2(dir.x, dir.z)
	_walk_phase += delta * (16.0 if _bolting else 8.0)
	_body.position.y = 0.05 + absf(sin(_walk_phase)) * 0.09
	_body.rotation.x = sin(_walk_phase) * 0.09
	_head.rotation.x = sin(_walk_phase) * 0.05

func _pick_target() -> void:
	var a := randf() * TAU
	var r := randf_range(6.0, 26.0)
	_target = _home + Vector3(cos(a) * r, 0.0, sin(a) * r)
