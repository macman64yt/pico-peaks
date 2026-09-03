extends CharacterBody3D

var world: Node
var kind := 0

var _home := Vector3.ZERO
var _target: Node3D
var _hp := 0
var _attack_t := 0.0
var _retarget_t := 0.0
var _flash := 0.0
var _dead := false
var _body: Node3D
var _mat: StandardMaterial3D
var _walk_phase := 0.0
var _despawning := false
var _provoked := false
var _provoke_t := 0.0
var _flee_t := 0.0

const ATTACK_INTERVAL := 1.0
const SPEED_PATROL := 3.0
const SPEED_CHASE := 6.8
const SPEED_FLEE := 8.5

func _ready() -> void:
	collision_layer = 1 | 2 | 4
	collision_mask = 1 | 4
	var grp := "bears" if kind == 0 else "boars"
	add_to_group(grp)
	_home = global_position
	_hp = 22 if kind == 0 else 6
	_build_body()
	_retarget_t = randf_range(0.0, 1.5)

func _build_body() -> void:
	if kind == 0:
		_build_bear()
	else:
		_build_boar()

func _build_bear() -> void:
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.36, 0.24, 0.14)
	_mat.roughness = 1.0
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.24, 0.16, 0.1)
	dark.roughness = 1.0
	var eye := StandardMaterial3D.new()
	eye.albedo_color = Color(0.1, 0.08, 0.06)
	_body = Node3D.new()
	add_child(_body)
	var torso := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(0.85, 0.75, 1.15)
	torso.mesh = tm
	torso.material_override = _mat
	torso.position = Vector3(0.0, 0.62, 0.0)
	_body.add_child(torso)
	var hump := MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(0.5, 0.3, 0.55)
	hump.mesh = hm
	hump.material_override = dark
	hump.position = Vector3(0.0, 1.0, -0.15)
	_body.add_child(hump)
	var head := MeshInstance3D.new()
	var hsm := BoxMesh.new()
	hsm.size = Vector3(0.42, 0.34, 0.4)
	head.mesh = hsm
	head.material_override = _mat
	head.position = Vector3(0.0, 0.82, 0.6)
	_body.add_child(head)
	var snout := MeshInstance3D.new()
	var snm := BoxMesh.new()
	snm.size = Vector3(0.2, 0.14, 0.2)
	snout.mesh = snm
	snout.material_override = dark
	snout.position = Vector3(0.0, 0.74, 0.88)
	_body.add_child(snout)
	for ex in [-0.14, 0.14]:
		var ear := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = 0.07
		em.height = 0.14
		ear.mesh = em
		ear.material_override = dark
		ear.position = Vector3(ex, 1.0, 0.55)
		_body.add_child(ear)
	for lz in [0.42, -0.46]:
		for side in [-0.32, 0.32]:
			var leg := MeshInstance3D.new()
			var lm := BoxMesh.new()
			lm.size = Vector3(0.16, 0.5, 0.16)
			leg.mesh = lm
			leg.material_override = dark
			leg.position = Vector3(side, 0.25, lz)
			_body.add_child(leg)
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.42
	cap.height = 1.5
	col.shape = cap
	col.position = Vector3(0.0, 0.7, 0.0)
	add_child(col)

func _build_boar() -> void:
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.42, 0.36, 0.28)
	_mat.roughness = 0.9
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.3, 0.25, 0.19)
	dark.roughness = 0.9
	var eye := StandardMaterial3D.new()
	eye.albedo_color = Color(0.08, 0.06, 0.05)
	_body = Node3D.new()
	add_child(_body)
	var torso := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(0.34, 0.34, 0.62)
	torso.mesh = tm
	torso.material_override = _mat
	torso.position = Vector3(0.0, 0.34, 0.0)
	_body.add_child(torso)
	var head := MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(0.24, 0.24, 0.3)
	head.mesh = hm
	head.material_override = _mat
	head.position = Vector3(0.0, 0.3, 0.4)
	_body.add_child(head)
	var plate_mat := StandardMaterial3D.new()
	plate_mat.albedo_color = Color(0.6, 0.5, 0.42)
	plate_mat.roughness = 0.9
	var snout_plate := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.16, 0.1, 0.14)
	snout_plate.mesh = sm
	snout_plate.material_override = plate_mat
	snout_plate.position = Vector3(0.0, 0.25, 0.58)
	_body.add_child(snout_plate)
	var tusk_mat := StandardMaterial3D.new()
	tusk_mat.albedo_color = Color(0.9, 0.88, 0.82)
	tusk_mat.roughness = 0.5
	for ex in [-0.08, 0.08]:
		var tusk := MeshInstance3D.new()
		var tkm := BoxMesh.new()
		tkm.size = Vector3(0.03, 0.06, 0.03)
		tusk.mesh = tkm
		tusk.material_override = tusk_mat
		tusk.position = Vector3(ex, 0.12, 0.6)
		tusk.rotation_degrees.x = 30.0
		_body.add_child(tusk)
	for lz in [0.2, -0.26]:
		for side in [-0.14, 0.14]:
			var leg := MeshInstance3D.new()
			var lm := BoxMesh.new()
			lm.size = Vector3(0.06, 0.28, 0.06)
			leg.mesh = lm
			leg.material_override = dark
			leg.position = Vector3(side, 0.14, lz)
			_body.add_child(leg)
	var tail := MeshInstance3D.new()
	var tam := CylinderMesh.new()
	tam.top_radius = 0.01
	tam.bottom_radius = 0.02
	tam.height = 0.16
	tail.mesh = tam
	tail.material_override = dark
	tail.position = Vector3(0.0, 0.4, -0.32)
	tail.rotation_degrees.x = 30.0
	_body.add_child(tail)
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.2
	cap.height = 0.7
	col.shape = cap
	col.position = Vector3(0.0, 0.33, 0.0)
	add_child(col)

func _height_at(x: float, z: float) -> float:
	if world and world.has_method("_height_at"):
		return world._height_at(x, z)
	return 0.0

func _is_day() -> bool:
	if world and world.get("_time_of_day") != null:
		var tod := fmod(float(world.get("_time_of_day")), 24.0)
		return tod >= 6.0 and tod < 18.0
	return true

func _find_target() -> Node3D:
	var t: Node3D = world._ai_target(self) if world and world.has_method("_ai_target") else null
	return t

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if _despawning:
		velocity = Vector3.ZERO
		global_position.y -= delta * 1.5
		if global_position.y < _height_at(global_position.x, global_position.z) - 1.5:
			queue_free()
		return
	_attack_t -= delta
	_retarget_t -= delta
	_provoke_t -= delta
	if _flee_t > 0.0:
		_flee_t -= delta
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0 and _mat:
			_mat.albedo_color = Color(0.36, 0.24, 0.14) if kind == 0 else Color(0.42, 0.36, 0.28)
	var target := _find_target()
	var hunting := (kind == 0) and target and global_position.distance_to(target.global_position) < 30.0
	var chasing := hunting or (_provoked and target and global_position.distance_to(target.global_position) < 45.0)
	if kind == 1 and not _provoked:
		if target and global_position.distance_to(target.global_position) < 6.0:
			chasing = false
			_flee(delta)
			velocity.y -= 24.0 * delta
			move_and_slide()
			return
	if chasing and target:
		var to := target.global_position - global_position
		to.y = 0.0
		var dist := to.length()
		if dist > 1.5:
			var dir := to.normalized()
			velocity.x = move_toward(velocity.x, dir.x * SPEED_CHASE, 14.0 * delta)
			velocity.z = move_toward(velocity.z, dir.z * SPEED_CHASE, 14.0 * delta)
			rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 8.0)
			if dist < 2.2 and _attack_t <= 0.0:
				_attack_t = ATTACK_INTERVAL
				_attack(target)
		else:
			velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
			if _attack_t <= 0.0:
				_attack_t = ATTACK_INTERVAL
				_attack(target)
	elif _flee_t > 0.0:
		_flee(delta)
	else:
		if _retarget_t <= 0.0:
			_retarget_t = randf_range(2.0, 6.0)
			var a := randf() * TAU
			var r := randf_range(8.0, 30.0)
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
	_walk_phase += delta * 12.0
	_body.position.y = 0.05 + absf(sin(_walk_phase)) * 0.06
	if kind == 0 and _body:
		_body.position.y = 0.05 + absf(sin(_walk_phase)) * 0.08

func _flee(delta: float) -> void:
	var away := global_position - (_target.global_position if _target else (_home + Vector3(0.0, 0.0, 40.0)))
	away.y = 0.0
	if away.length() < 0.5:
		return
	var dir := away.normalized()
	velocity.x = move_toward(velocity.x, dir.x * SPEED_FLEE, 14.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * SPEED_FLEE, 14.0 * delta)
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 9.0)

func _attack(t: Node3D) -> void:
	if t == null or world == null:
		return
	if t.has_method("hit"):
		t.hit(14 if kind == 0 else 5)

func hit(dmg: int) -> void:
	if _dead:
		return
	_hp -= dmg
	_flash = 0.12
	if _mat:
		_mat.albedo_color = Color(0.85, 0.25, 0.15)
	if kind == 1:
		_provoked = true
		_provoke_t = 8.0
	if _hp <= 0:
		_die()

func punched() -> void:
	if _dead:
		return
	hit(3)

func _die() -> void:
	_dead = true
	velocity = Vector3.ZERO
	var fn := "_bear_died" if kind == 0 else "_boar_died"
	if world and world.has_method(fn):
		world.call(fn, self)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "rotation:z", PI / 2.0, 0.4)
	tw.tween_property(self, "position:y", position.y - 0.2, 0.4)
	tw.tween_callback(queue_free)

func do_despawn() -> void:
	if _dead or _despawning:
		return
	_despawning = true