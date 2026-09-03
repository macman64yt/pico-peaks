extends CharacterBody3D

var world: Node

var _home := Vector3.ZERO
var _target: Node3D
var _hp := 8
var _attack_t := 0.0
var _retarget_t := 0.0
var _flash := 0.0
var _dead := false
var _body: Node3D
var _tail_node: Node3D
var _wolf_mat: StandardMaterial3D
var _walk_phase := 0.0
var _despawning := false

const ATTACK_INTERVAL := 0.9
const SPEED_PATROL := 3.5
const SPEED_CHASE := 7.8
const SPEED_FLEE := 9.0
const DMG := 8

func _ready() -> void:
	collision_layer = 1 | 2 | 4
	collision_mask = 1 | 4
	add_to_group("wolves")
	_home = global_position
	_hp = 8
	_build_body()
	_retarget_t = randf_range(0.0, 1.5)

func _build_body() -> void:
	_wolf_mat = StandardMaterial3D.new()
	_wolf_mat.albedo_color = Color(0.45, 0.43, 0.4)
	_wolf_mat.roughness = 0.9
	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.3, 0.28, 0.26)
	dark_mat.roughness = 0.9
	var belly_mat := StandardMaterial3D.new()
	belly_mat.albedo_color = Color(0.58, 0.55, 0.5)
	belly_mat.roughness = 0.85
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(1.0, 0.85, 0.2)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0, 0.85, 0.2) * 0.5

	_body = Node3D.new()
	add_child(_body)
	var torso := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(0.32, 0.28, 0.68)
	torso.mesh = tm
	torso.material_override = _wolf_mat
	torso.position = Vector3(0.0, 0.38, 0.0)
	_body.add_child(torso)
	var belly := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.28, 0.16, 0.42)
	belly.mesh = bm
	belly.material_override = belly_mat
	belly.position = Vector3(0.0, 0.26, 0.02)
	_body.add_child(belly)
	var head_pivot := Node3D.new()
	head_pivot.position = Vector3(0.0, 0.46, 0.36)
	_body.add_child(head_pivot)
	var skull := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.22, 0.18, 0.3)
	skull.mesh = sm
	skull.material_override = _wolf_mat
	skull.position = Vector3(0.0, 0.04, 0.1)
	head_pivot.add_child(skull)
	var snout := MeshInstance3D.new()
	var ssm := BoxMesh.new()
	ssm.size = Vector3(0.12, 0.08, 0.14)
	snout.mesh = ssm
	snout.material_override = dark_mat
	snout.position = Vector3(0.0, -0.02, 0.2)
	head_pivot.add_child(snout)
	for ex in [-0.07, 0.07]:
		var ear := MeshInstance3D.new()
		var em := BoxMesh.new()
		em.size = Vector3(0.04, 0.08, 0.03)
		ear.mesh = em
		ear.material_override = dark_mat
		ear.position = Vector3(ex, 0.14, 0.02)
		ear.rotation_degrees.z = -20.0 if ex < 0 else 20.0
		head_pivot.add_child(ear)
	for ex in [-0.06, 0.06]:
		var eye := MeshInstance3D.new()
		var eem := SphereMesh.new()
		eem.radius = 0.018
		eem.height = 0.036
		eye.mesh = eem
		eye.material_override = eye_mat
		eye.position = Vector3(ex, 0.07, 0.14)
		head_pivot.add_child(eye)
	for lz in [0.22, -0.2]:
		for side in [-0.15, 0.15]:
			var leg := MeshInstance3D.new()
			var lm := BoxMesh.new()
			lm.size = Vector3(0.05, 0.28, 0.05)
			leg.mesh = lm
			leg.material_override = dark_mat
			leg.position = Vector3(side, 0.15, lz)
			_body.add_child(leg)
	_tail_node = Node3D.new()
	_tail_node.position = Vector3(0.0, 0.46, -0.36)
	_body.add_child(_tail_node)
	var tail := MeshInstance3D.new()
	var tam := CylinderMesh.new()
	tam.top_radius = 0.008
	tam.bottom_radius = 0.022
	tam.height = 0.28
	tail.mesh = tam
	tail.material_override = _wolf_mat
	tail.position = Vector3(0.0, 0.1, 0.0)
	tail.rotation_degrees.x = 35.0
	_tail_node.add_child(tail)

	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.28
	cap.height = 0.9
	col.shape = cap
	col.position = Vector3(0.0, 0.45, 0.0)
	add_child(col)

func _height_at(x: float, z: float) -> float:
	if world and world.has_method("_height_at"):
		return world._height_at(x, z)
	return 0.0

func _is_night() -> bool:
	if world and world.get("_time_of_day") != null:
		var tod := fmod(float(world.get("_time_of_day")), 24.0)
		return tod >= 18.0 or tod < 6.0
	return false

func _find_target() -> Node3D:
	var t: Node3D = world._ai_target(self) if world and world.has_method("_ai_target") else null
	return t

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if _despawning:
		velocity = Vector3.ZERO
		global_position.y -= delta * 1.5
		_body.position.y = maxf(_body.position.y - delta * 2.0, -0.5)
		if global_position.y < _height_at(global_position.x, global_position.z) - 1.5:
			queue_free()
		return
	var night := _is_night()
	_attack_t -= delta
	_retarget_t -= delta
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0 and _wolf_mat:
			_wolf_mat.albedo_color = Color(0.45, 0.43, 0.4)
	if not night:
		if global_position.distance_to(_home) > 5.0:
			var to := _home - global_position
			to.y = 0.0
			var dir := to.normalized()
			velocity.x = move_toward(velocity.x, dir.x * SPEED_FLEE, 12.0 * delta)
			velocity.z = move_toward(velocity.z, dir.z * SPEED_FLEE, 12.0 * delta)
			rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 6.0)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
		velocity.y -= 24.0 * delta
		move_and_slide()
		_walk_phase += delta * 4.0
		if velocity.length() > 0.5:
			_body.position.y = 0.05 + absf(sin(_walk_phase)) * 0.05
		else:
			_body.position.y = 0.05 + absf(sin(Time.get_ticks_msec() / 1000.0 * 2.0)) * 0.03
		return
	var target := _find_target()
	if target and global_position.distance_to(target.global_position) < 40.0:
		var to := target.global_position - global_position
		to.y = 0.0
		var dist := to.length()
		if dist > 1.5:
			var dir := to.normalized()
			var spd := SPEED_CHASE
			velocity.x = move_toward(velocity.x, dir.x * spd, 14.0 * delta)
			velocity.z = move_toward(velocity.z, dir.z * spd, 14.0 * delta)
			rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 8.0)
			if dist < 2.0 and _attack_t <= 0.0:
				_attack_t = ATTACK_INTERVAL
				_attack(target)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			if _attack_t <= 0.0:
				_attack_t = ATTACK_INTERVAL
				_attack(target)
	else:
		if _retarget_t <= 0.0:
			_retarget_t = randf_range(2.0, 6.0)
			var a := randf() * TAU
			var r := randf_range(10.0, 35.0)
			_target = null
			var dest := _home + Vector3(cos(a) * r, 0.0, sin(a) * r)
			var to := dest - global_position
			to.y = 0.0
			var dir := to.normalized()
			velocity.x = move_toward(velocity.x, dir.x * SPEED_PATROL, 8.0 * delta)
			velocity.z = move_toward(velocity.z, dir.z * SPEED_PATROL, 8.0 * delta)
		elif velocity.length() > 0.5:
			velocity.x = move_toward(velocity.x, 0.0, 4.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 4.0 * delta)
	velocity.y -= 24.0 * delta
	move_and_slide()
	_walk_phase += delta * 14.0
	_body.position.y = 0.05 + absf(sin(_walk_phase)) * 0.09
	_body.rotation.x = sin(_walk_phase) * 0.07
	if _tail_node:
		_tail_node.rotation.x = sin(_walk_phase * 0.8) * 0.15 - 0.3

func _attack(t: Node3D) -> void:
	if t == null or world == null:
		return
	if t.has_method("hit"):
		t.hit(DMG)

func hit(dmg: int) -> void:
	if _dead:
		return
	_hp -= dmg
	_flash = 0.12
	if _wolf_mat:
		_wolf_mat.albedo_color = Color(0.85, 0.25, 0.15)
	if _hp <= 0:
		_die()

func punched() -> void:
	if _dead:
		return
	if world and world.has_method("_post_chat"):
		world._post_chat("Wolf", "Grrr...")
	hit(3)

func _die() -> void:
	_dead = true
	velocity = Vector3.ZERO
	if world and world.has_method("_wolf_died"):
		world._wolf_died(self)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "rotation:z", PI / 2.0, 0.4)
	tw.tween_property(self, "position:y", position.y - 0.2, 0.4)
	tw.tween_callback(queue_free)

func do_despawn() -> void:
	if _dead or _despawning:
		return
	_despawning = true
