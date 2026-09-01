extends CharacterBody3D

var world: Node

var _player_in: CharacterBody3D
var _speed := 0.0
var _steer := 0.0
var _cam: Camera3D
var _enter_frame := -100
var _t := 0.0
var _wake: GPUParticles3D
var net_gas := 0.0
var net_turn := 0.0
var speed_mult := 1.0

const MAX_SPEED := 7.5
const ACCEL := 3.6
const REV_LIMIT := -3.0
const TURN := 1.5
const WATER_Y := 0.0

var interact_hint := "[E] Board boat"


func _ready() -> void:
	collision_layer = 1 | 2
	collision_mask = 1
	_cam = Camera3D.new()
	_cam.name = "Camera3D"
	_cam.fov = 74.0
	_cam.near = 0.1
	_cam.far = 1200.0
	_cam.position = Vector3(0.0, 2.0, -3.4)
	_cam.current = false
	add_child(_cam)
	_wake = GPUParticles3D.new()
	_wake.one_shot = false
	_wake.amount = 60
	_wake.lifetime = 1.1
	var wm := ParticleProcessMaterial.new()
	wm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	wm.emission_box_extents = Vector3(0.5, 0.05, 0.6)
	wm.direction = Vector3(0.0, 1.0, 0.0)
	wm.spread = 25.0
	wm.gravity = Vector3(0.0, 0.6, 0.0)
	wm.initial_velocity_min = 0.2
	wm.initial_velocity_max = 0.8
	wm.scale_min = 0.12
	wm.scale_max = 0.3
	wm.color = Color(0.9, 0.95, 0.98, 0.4)
	_wake.process_material = wm
	_wake.position = Vector3(0.0, 0.1, -1.9)
	add_child(_wake)
	_wake.emitting = false
	if world and bool(world.get("_client")):
		collision_mask = 0


func _is_local_driver() -> bool:
	if world == null or not bool(world.get("_client")):
		return false
	var p: CharacterBody3D = world.get("_player")
	if p == null:
		return false
	return bool(p.get("in_boat"))


func interact() -> void:
	if world and world.has_method("_enter_boat"):
		world._enter_boat(self)


func _wind_velocity() -> Vector3:
	if world == null:
		return Vector3.ZERO
	var ws: float = float(world.get("_wind_speed"))
	var dir: float = float(world.get("_wind_dir"))
	return Vector3(cos(dir), 0.0, sin(dir)) * ws * 1.4


func _physics_process(delta: float) -> void:
	_t += delta
	if world and bool(world.get("_client")):
		_ghost_physics(delta)
		return
	var bob := sin(_t * 1.3) * 0.15
	if not _player_in:
		_speed = move_toward(_speed, 0.0, ACCEL * delta)
		_steer = move_toward(_steer, 0.0, delta * 4.0)
		velocity.x = move_toward(velocity.x, 0.0, ACCEL * delta)
		velocity.z = move_toward(velocity.z, 0.0, ACCEL * delta)
		velocity += _wind_velocity() * delta * 0.35
		global_position.y = WATER_Y + 0.45 + bob
		rotation.z = sin(_t * 0.9) * 0.05
		move_and_slide()
		_wake.emitting = false
		return
	if Input.is_action_just_pressed("interact") \
			and Engine.get_physics_frames() > _enter_frame + 1 \
			and world and world.has_method("_exit_boat") \
			and not bool(_player_in.get("net_controlled")):
		world._exit_boat(self)
		return
	var gas := net_gas if bool(_player_in.get("net_controlled")) else Input.get_axis("move_back", "move_forward")
	var turn := net_turn if bool(_player_in.get("net_controlled")) else Input.get_axis("move_right", "move_left")
	if Engine.get_physics_frames() <= _enter_frame + 1:
		gas = 0.0
		turn = 0.0
	_speed = clampf(_speed + gas * ACCEL * delta, REV_LIMIT * speed_mult, MAX_SPEED * speed_mult)
	if absf(_speed) > 0.3:
		_steer = move_toward(_steer, turn, delta * 3.0)
		rotation.y += _steer * TURN * delta
	else:
		_steer = move_toward(_steer, 0.0, delta * 3.0)
	velocity = transform.basis.z * _speed
	velocity += _wind_velocity() * 0.12
	velocity.y = 0.0
	global_position.y = WATER_Y + 0.45 + bob
	move_and_slide()
	_wake.emitting = absf(_speed) > 1.0
	if not bool(_player_in.get("net_controlled")):
		var dir := transform.basis.z
		_cam.look_at(global_position + dir * 4.0 + Vector3(0.0, 1.0, 0.0), Vector3.UP)


func _ghost_physics(delta: float) -> void:
	var k := clampf(delta * 12.0, 0.0, 1.0)
	global_position = global_position.lerp(get_meta("net_target", global_position), k)
	rotation.y = lerp_angle(rotation.y, float(get_meta("net_rot", rotation.y)), k)
	if _is_local_driver():
		_cam.current = true
		var dir := transform.basis.z
		_cam.look_at(global_position + dir * 4.0 + Vector3(0.0, 1.0, 0.0), Vector3.UP)


func set_player(p: CharacterBody3D) -> void:
	_player_in = p
