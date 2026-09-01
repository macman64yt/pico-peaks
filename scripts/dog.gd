extends Node3D

var world: Node

var _home := Vector3.ZERO
var _target := Vector3.ZERO
var _pause := 0.0
var _walk_phase := 0.0
var _body: Node3D
var _tail: Node3D
var _bolting := false
var _was_storm := false

func _ready() -> void:
	_home = position
	_build_body()
	_pause = randf_range(0.5, 3.0)
	_pick_target()

func _build_body() -> void:
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.72, 0.58, 0.42)
	body_mat.roughness = 0.9
	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.42, 0.32, 0.24)
	dark_mat.roughness = 0.9
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.3, 0.35, 0.95)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(0.3, 0.35, 0.95)
	eye_mat.emission_energy_multiplier = 2.5

	_body = Node3D.new()
	add_child(_body)
	var torso := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(0.32, 0.24, 0.62)
	torso.mesh = tm
	torso.material_override = body_mat
	torso.position = Vector3(0.0, 0.3, 0.0)
	_body.add_child(torso)
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.17
	hm.height = 0.3
	head.mesh = hm
	head.material_override = body_mat
	head.position = Vector3(0.0, 0.44, 0.3)
	_body.add_child(head)
	var muzzle := MeshInstance3D.new()
	var mm := BoxMesh.new()
	mm.size = Vector3(0.1, 0.07, 0.1)
	muzzle.mesh = mm
	muzzle.material_override = dark_mat
	muzzle.position = Vector3(0.0, 0.4, 0.41)
	_body.add_child(muzzle)
	for ex in [-0.08, 0.08]:
		var ear := MeshInstance3D.new()
		var em := CylinderMesh.new()
		em.top_radius = 0.035
		em.bottom_radius = 0.06
		em.height = 0.14
		ear.mesh = em
		ear.material_override = dark_mat
		ear.rotation_degrees = Vector3(0.0, 0.0, ex * 60.0)
		ear.position = Vector3(ex * 1.4, 0.56, 0.3)
		_body.add_child(ear)
	for ex in [-0.06, 0.06]:
		var eye := MeshInstance3D.new()
		var ebm := BoxMesh.new()
		ebm.size = Vector3(0.04, 0.04, 0.02)
		eye.mesh = ebm
		eye.material_override = eye_mat
		eye.position = Vector3(ex, 0.46, 0.42)
		_body.add_child(eye)
	for lz in [0.2, -0.2]:
		for side in [-0.15, 0.15]:
			var leg := MeshInstance3D.new()
			var lm := BoxMesh.new()
			lm.size = Vector3(0.08, 0.18, 0.08)
			leg.mesh = lm
			leg.material_override = dark_mat
			leg.position = Vector3(side, 0.11, lz)
			_body.add_child(leg)
	_tail = Node3D.new()
	_tail.position = Vector3(0.0, 0.4, -0.31)
	_body.add_child(_tail)
	var tail_mesh := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.03
	cm.bottom_radius = 0.05
	cm.height = 0.45
	tail_mesh.mesh = cm
	tail_mesh.material_override = dark_mat
	tail_mesh.position = Vector3(0.0, 0.22, 0.0)
	_tail.add_child(tail_mesh)

func _storm() -> bool:
	return world != null and int(world.get("_weather")) >= 3

func _zombie_near() -> bool:
	for z in get_tree().get_nodes_in_group("zombies"):
		var d: float = global_position.distance_to((z as Node3D).global_position)
		if d < 18.0:
			return true
	return false

func _physics_process(delta: float) -> void:
	var storm := _storm()
	if storm and not _was_storm:
		_was_storm = true
		_bolting = true
		_target = _home
	elif not storm:
		_was_storm = false
	var zombie_scare := _zombie_near()
	if zombie_scare:
		_bolting = true
		_target = _home
	elif not _storm() and _bolting and global_position.distance_to(_home) < 2.0:
		_bolting = false

	if _pause > 0.0:
		_pause -= delta
		if _bolting or storm:
			_tail.rotation.x = -0.5
		elif _storm():
			_tail.rotation.x = -0.5
		else:
			_tail.rotation.x = sin(Time.get_ticks_msec() / 1000.0 * 6.0) * 0.5
		return

	var speed := 7.0 if _bolting else 3.2
	var follow := false
	if not _bolting and not _storm() and world != null and world.has_method("_ai_target"):
		var pl: Node3D = world._ai_target(self)
		if pl and global_position.distance_to((pl as Node3D).global_position) < 26.0:
			var pc := (pl as Node3D).global_position
			var off := Vector3(2.5, 0.0, 0.0) + Vector3(0.0, 0.0, 2.5)
			_target = pc + off
			if global_position.distance_to(_target) < 3.0:
				_pause = randf_range(0.4, 1.2)
				_tail.rotation.x = sin(Time.get_ticks_msec() / 1000.0 * 14.0) * 0.7
				return
			follow = true

	var to := _target - position
	to.y = 0.0
	if to.length() < 0.4:
		if _bolting:
			_pause = randf_range(8.0, 16.0)
			_bolting = false
		else:
			_pause = randf_range(1.5, 5.0)
			_pick_target()
		return
	var dir := to.normalized()
	position.x += dir.x * speed * delta
	position.z += dir.z * speed * delta
	if world and world.has_method("_height_at"):
		var h: float = world._height_at(position.x, position.z)
		position.y = maxf(h, 0.05) + 0.05
	rotation.y = atan2(dir.x, dir.z)
	_walk_phase += delta * (14.0 if _bolting else 9.0)
	_body.position.y = 0.05 + absf(sin(_walk_phase)) * 0.05
	_body.rotation.x = sin(_walk_phase) * 0.06
	var wag := 12.0 if follow else 5.0
	_tail.rotation.x = sin(Time.get_ticks_msec() / 1000.0 * wag) * (0.6 if follow else 0.3) + absf(sin(_walk_phase)) * 0.2
	if _bolting:
		_tail.rotation.x = -0.5

func _pick_target() -> void:
	var a := randf() * TAU
	var r := randf_range(3.0, 18.0)
	_target = _home + Vector3(cos(a) * r, 0.0, sin(a) * r)
