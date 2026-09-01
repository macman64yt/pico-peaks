extends CharacterBody3D

var world: Node

var _home := Vector3.ZERO
var _target: Node3D
var _hp := 6
var _attack_t := 0.0
var _retarget_t := 0.0
var _flash := 0.0
var _dead := false
var _base_color := Color(0.42, 0.55, 0.32)
var _robe_mat: StandardMaterial3D
var net_slave := false
var ztype := 0
var _emerging := 0.0
var _sinking := 0.0
var _ground_y := 0.0

const ATTACK_INTERVAL := 1.1
const SPEED_N := 2.6
const SPEED_R := 4.8
const SPEED_B := 1.5
const HP_N := 6
const HP_R := 3
const HP_B := 16
const DMG_N := 6
const DMG_R := 4
const DMG_B := 12


func _difficulty() -> float:
	var d := 1
	if world and is_instance_valid(world) and world.get("_time_of_day") != null:
		d = int(floor(float(world.get("_time_of_day")) / 24.0)) + 1
	return clampf(1.0 + float(d - 1) * 0.12, 1.0, 2.2)


func _speed() -> float:
	var base := SPEED_R if ztype == 1 else (SPEED_B if ztype == 2 else SPEED_N)
	return base * (1.0 + (_difficulty() - 1.0) * 0.35)


func _dmg() -> int:
	var base := DMG_R if ztype == 1 else (DMG_B if ztype == 2 else DMG_N)
	return maxi(1, roundi(float(base) * (1.0 + (_difficulty() - 1.0) * 0.4)))


func _ready() -> void:
	collision_layer = 1 | 4
	collision_mask = 1 | 4
	add_to_group("zombies")
	if net_slave:
		collision_layer = 4
		collision_mask = 0
	_home = global_position
	_retarget_t = randf_range(0.0, 1.0)
	_hp = HP_N
	if ztype == 1:
		_hp = HP_R
		scale = Vector3.ONE * 0.85
	elif ztype == 2:
		_hp = HP_B
		scale = Vector3.ONE * 1.35
	_hp = maxi(1, roundi(float(_hp) * _difficulty()))
	var skin_mat := StandardMaterial3D.new()
	if ztype == 1:
		skin_mat.albedo_color = Color(0.78, 0.48, 0.38)
	elif ztype == 2:
		skin_mat.albedo_color = Color(0.30, 0.42, 0.34)
	else:
		skin_mat.albedo_color = Color(0.58, 0.72, 0.50)
	skin_mat.roughness = 0.9
	var robe_mat := StandardMaterial3D.new()
	if ztype == 1:
		robe_mat.albedo_color = Color(0.52, 0.32, 0.30)
	elif ztype == 2:
		robe_mat.albedo_color = Color(0.16, 0.15, 0.17)
	else:
		robe_mat.albedo_color = _base_color
	robe_mat.roughness = 1.0
	_robe_mat = robe_mat
	var robe := MeshInstance3D.new()
	var rm := BoxMesh.new()
	rm.size = Vector3(0.6, 0.95, 0.35)
	robe.mesh = rm
	robe.material_override = robe_mat
	robe.position = Vector3(0.0, 0.72, 0.0)
	add_child(robe)
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.15
	hm.height = 0.28
	head.mesh = hm
	head.material_override = skin_mat
	head.position = Vector3(0.0, 1.34, 0.0)
	head.rotation_degrees = Vector3(18.0, 0.0, 0.0)
	add_child(head)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(1.0, 0.25, 0.1)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0, 0.3, 0.1)
	for ex in [-0.08, 0.08]:
		var eye := MeshInstance3D.new()
		var em := BoxMesh.new()
		em.size = Vector3(0.05, 0.03, 0.02)
		eye.mesh = em
		eye.material_override = eye_mat
		eye.position = Vector3(ex, 1.38, -0.14)
		add_child(eye)
	var arm_mat := StandardMaterial3D.new()
	arm_mat.albedo_color = Color(0.38, 0.50, 0.30)
	arm_mat.roughness = 1.0
	for ax in [-0.36, 0.36]:
		var arm := MeshInstance3D.new()
		var am := BoxMesh.new()
		am.size = Vector3(0.11, 0.55, 0.11)
		arm.mesh = am
		arm.material_override = arm_mat
		arm.position = Vector3(ax, 1.0, -0.22)
		arm.rotation_degrees = Vector3(35.0, 0.0, 0.0)
		add_child(arm)
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.7
	col.shape = cap
	col.position = Vector3(0.0, 0.85, 0.0)
	add_child(col)
	if not net_slave:
		_ground_y = global_position.y
		global_position.y = _ground_y - 1.4
		_emerging = randf_range(0.6, 2.4)


func _physics_process(delta: float) -> void:
	if _dead:
		return
	if net_slave:
		_interpolate_slave(delta)
		return
	if _sinking > 0.0:
		_sinking -= delta
		velocity = Vector3.ZERO
		global_position.y -= delta * 1.3
		if _sinking <= 0.0:
			queue_free()
		return
	if _emerging > 0.0:
		_emerging -= delta
		velocity = Vector3.ZERO
		var t := 1.0 - clampf(_emerging, 0.0, 1.0)
		global_position.y = _ground_y - 1.4 * (1.0 - t * t)
		rotation.y += delta * 0.6
		if _emerging <= 0.0:
			global_position.y = _ground_y
		return
	_attack_t -= delta
	_retarget_t -= delta
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0 and _robe_mat:
			_robe_mat.albedo_color = _base_color
	velocity.y -= 24.0 * delta
	var target := _find_target()
	_target = target
	if target:
		var to := (target as Node3D).global_position - global_position
		to.y = 0.0
		var dist := to.length()
		if dist > 1.5:
			var dir := to.normalized()
			velocity.x = move_toward(velocity.x, dir.x * _speed(), 10.0 * delta)
			velocity.z = move_toward(velocity.z, dir.z * _speed(), 10.0 * delta)
			rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 6.0)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
			if _attack_t <= 0.0:
				_attack_t = ATTACK_INTERVAL
				_attack(target)
	else:
		var to := _home - global_position
		to.y = 0.0
		if to.length() > 2.0:
			var dir := to.normalized()
			velocity.x = move_toward(velocity.x, dir.x * _speed() * 0.5, 8.0 * delta)
			velocity.z = move_toward(velocity.z, dir.z * _speed() * 0.5, 8.0 * delta)
	move_and_slide()


func _find_target() -> Node3D:
	var best: Node3D = null
	var best_d := INF
	if world:
		best = world._ai_target(self)
		if best:
			best_d = global_position.distance_to(best.global_position)
		for n in get_tree().get_nodes_in_group("npc"):
			if bool(n.get("_dead")):
				continue
			var d: float = global_position.distance_to((n as Node3D).global_position)
			if d < best_d:
				best_d = d
				best = n
	if best and bool(best.get_meta("is_player", false)) and world and world._shrine_guards(global_position):
		return null
	return best


func _interpolate_slave(delta: float) -> void:
	var k := clampf(delta * 12.0, 0.0, 1.0)
	global_position = global_position.lerp(get_meta("net_target", global_position), k)
	rotation.y = lerp_angle(rotation.y, float(get_meta("net_rot", rotation.y)), k)


func _attack(t: Node3D) -> void:
	if t == null or world == null:
		return
	var is_player := bool(t.get_meta("is_player", false))
	if t.has_method("hit"):
		t.hit(_dmg() if is_player else maxi(1, int(_dmg() * 0.6)))


func do_sink() -> void:
	if _dead or _sinking > 0.0:
		return
	_sinking = 1.4
	_target = null


func hit(dmg: int) -> void:
	if _dead:
		return
	_hp -= dmg
	_flash = 0.12
	if _robe_mat:
		_robe_mat.albedo_color = Color(0.85, 0.25, 0.15)
	if _hp <= 0:
		_die()


func punched() -> void:
	if _dead:
		return
	if world and world.has_method("_post_chat"):
		world._post_chat("???", "Grrr...")
	hit(2)


func _die() -> void:
	_dead = true
	velocity = Vector3.ZERO
	if world and world.has_method("_zombie_died"):
		world._zombie_died(self)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "rotation:z", PI / 2.0, 0.5)
	tw.tween_property(self, "position:y", position.y - 0.25, 0.5)
	tw.tween_callback(queue_free)
