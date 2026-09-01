extends Node3D

var world: Node

var _home := Vector3.ZERO
var _target := Vector3.ZERO
var _pause := 0.0
var _walk_phase := 0.0
var _body: Node3D
var _tail: Node3D
var _curious := false

func _ready() -> void:
	_home = position
	_build_body()
	_pick_target()

func _build_body() -> void:
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.85, 0.72, 0.5)
	body_mat.roughness = 0.9
	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.45, 0.35, 0.25)
	dark_mat.roughness = 0.9
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(0.35, 0.9, 0.55)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(0.35, 0.9, 0.55)
	eye_mat.emission_energy_multiplier = 2.5

	_body = Node3D.new()
	add_child(_body)
	var torso := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(0.3, 0.22, 0.55)
	torso.mesh = tm
	torso.material_override = body_mat
	torso.position = Vector3(0.0, 0.28, 0.0)
	_body.add_child(torso)
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.15
	hm.height = 0.26
	head.mesh = hm
	head.material_override = body_mat
	head.position = Vector3(0.0, 0.4, 0.28)
	_body.add_child(head)
	for ex in [-0.07, 0.07]:
		var ear := MeshInstance3D.new()
		var em := CylinderMesh.new()
		em.top_radius = 0.03
		em.bottom_radius = 0.05
		em.height = 0.09
		ear.mesh = em
		ear.material_override = dark_mat
		ear.position = Vector3(ex, 0.55, 0.28)
		_body.add_child(ear)
	for ex in [-0.055, 0.055]:
		var eye := MeshInstance3D.new()
		var ebm := BoxMesh.new()
		ebm.size = Vector3(0.035, 0.035, 0.02)
		eye.mesh = ebm
		eye.material_override = eye_mat
		eye.position = Vector3(ex, 0.42, 0.4)
		_body.add_child(eye)
	for lz in [0.18, -0.18]:
		for side in [-0.14, 0.14]:
			var leg := MeshInstance3D.new()
			var lm := BoxMesh.new()
			lm.size = Vector3(0.07, 0.16, 0.07)
			leg.mesh = lm
			leg.material_override = dark_mat
			leg.position = Vector3(side, 0.1, lz)
			_body.add_child(leg)
	_tail = Node3D.new()
	_tail.position = Vector3(0.0, 0.35, -0.28)
	_body.add_child(_tail)
	var tail_mesh := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.02
	cm.bottom_radius = 0.04
	cm.height = 0.4
	tail_mesh.mesh = cm
	tail_mesh.material_override = dark_mat
	tail_mesh.position = Vector3(0.0, 0.2, 0.0)
	_tail.add_child(tail_mesh)

func _physics_process(delta: float) -> void:
	if _pause > 0.0:
		_pause -= delta
		_tail.rotation.x = sin(Time.get_ticks_msec() / 1000.0 * 5.0) * 0.3
		return
	var to := _target - position
	to.y = 0.0
	if to.length() < 0.3:
		_pause = randf_range(1.5, 5.0)
		_pick_target()
		return
	var dir := to.normalized()
	position.x += dir.x * 1.5 * delta
	position.z += dir.z * 1.5 * delta
	if world and world.has_method("_height_at"):
		position.y = world._height_at(position.x, position.z) + 0.05
	rotation.y = atan2(dir.x, dir.z)
	_walk_phase += delta * 9.0
	_body.position.y = 0.05 + absf(sin(_walk_phase)) * 0.045
	_body.rotation.x = sin(_walk_phase) * 0.06
	_tail.rotation.x = sin(Time.get_ticks_msec() / 1000.0 * 5.0) * 0.25 + absf(sin(_walk_phase)) * 0.2

func _pick_target() -> void:
	if world != null and world.has_method("_ai_target"):
		var pl: Node3D = world._ai_target(self)
		if pl and global_position.distance_to((pl as Node3D).global_position) < 7.0:
			var away := global_position - (pl as Node3D).global_position
			away.y = 0.0
			if away.length() < 0.01:
				away = Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0))
			_target = global_position + away.normalized() * 6.0
			_curious = false
			return
	var a := randf() * TAU
	var r := randf_range(2.0, 14.0)
	_target = _home + Vector3(cos(a) * r, 0.0, sin(a) * r)
	_curious = false
