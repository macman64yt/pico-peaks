extends CharacterBody3D

var world: Node

var _player_in: CharacterBody3D
var _speed := 0.0
var _steer := 0.0
var _cam: Camera3D
var _enter_frame := -100
var net_gas := 0.0
var net_turn := 0.0
var net_boost := false

const MAX_SPEED := 22.0
const BOOST_SPEED := 34.0
const REV_LIMIT := -7.0
const ACCEL := 12.0
const BOOST_ACCEL := 30.0
const TURN := 3.2
const TURBO_SPOOL_FULL := 0.9
const TURBO_BLOWDOWN := 1.0

var boost := 0.0
var _rpm := 0.12
var _spool := 0.0
var _blowoff := 0.0
var _est_speed := 0.0
var _engine_audio: AudioStreamPlayer
var _turbo_audio: AudioStreamPlayer
var _eng_pb: AudioStreamGeneratorPlayback
var _trb_pb: AudioStreamGeneratorPlayback
var _e_phase := 0.0
var _t_phase := 0.0
var _b_phase := 0.0
var _noise_sm := 0.0
var _noise_sm2 := 0.0
var _fov := 68.0

var interact_hint := "[E] Mount bike"


func _ready() -> void:
	collision_layer = 1 | 2
	collision_mask = 1
	_cam = Camera3D.new()
	_cam.name = "Camera3D"
	_cam.fov = _fov
	_cam.near = 0.1
	_cam.far = 1200.0
	_cam.position = Vector3(0.0, 1.8, -4.5)
	_cam.current = false
	add_child(_cam)
	if world and bool(world.get("_client")):
		collision_mask = 0
		_setup_audio()


func _setup_audio() -> void:
	_engine_audio = AudioStreamPlayer.new()
	_engine_audio.name = "EngineAudio"
	var es := AudioStreamGenerator.new()
	es.mix_rate = 22050.0
	es.buffer_length = 0.3
	_engine_audio.stream = es
	add_child(_engine_audio)
	_turbo_audio = AudioStreamPlayer.new()
	_turbo_audio.name = "TurboAudio"
	var ts := AudioStreamGenerator.new()
	ts.mix_rate = 22050.0
	ts.buffer_length = 0.3
	_turbo_audio.stream = ts
	add_child(_turbo_audio)


func _is_local_driver() -> bool:
	if world == null or not bool(world.get("_client")):
		return false
	var p: CharacterBody3D = world.get("_player")
	if p == null:
		return false
	var cid: int = int(get_meta("car_id", -1))
	return int(p.get("in_car_id")) == cid


func interact() -> void:
	if world and world.has_method("_enter_bike"):
		world._enter_bike(self)


func _tick_turbo(delta: float, throttle: float, speed_now: float) -> void:
	var spd_norm := clampf(absf(speed_now) / MAX_SPEED, 0.0, 1.3)
	var target_rpm := clampf(0.12 + spd_norm * 0.95, 0.0, 1.0)
	_rpm = lerpf(_rpm, target_rpm, clampf(delta * 8.0, 0.0, 1.0))
	var rate := lerpf(0.3, 1.3, throttle * _rpm)
	_spool = move_toward(_spool, rate, delta * 3.0)
	if throttle > 0.05:
		boost = move_toward(boost, 1.0, _spool * delta)
	else:
		boost = move_toward(boost, 0.0, delta / TURBO_BLOWDOWN)
	if _blowoff <= 0.0 and throttle < 0.05 and boost > 0.5:
		_blowoff = 1.0


func _physics_process(delta: float) -> void:
	if world and bool(world.get("_client")):
		_ghost_physics(delta)
		return
	if not _player_in:
		boost = move_toward(boost, 0.0, delta / TURBO_BLOWDOWN)
		_rpm = lerpf(_rpm, 0.12, clampf(delta * 4.0, 0.0, 1.0))
		_spool = 0.0
		_speed = move_toward(_speed, 0.0, ACCEL * delta)
		_steer = move_toward(_steer, 0.0, delta * 4.0)
		velocity = transform.basis.z * _speed
		velocity.y -= 24.0 * delta
		move_and_slide()
		return
	var net_driven := bool(_player_in.get("net_controlled"))
	if Input.is_action_just_pressed("interact") \
			and Engine.get_physics_frames() > _enter_frame + 1 \
			and world and world.has_method("_exit_bike") \
			and not net_driven:
		world._exit_bike(self)
		return
	var gas := net_gas if net_driven else Input.get_axis("move_back", "move_forward")
	var turn := net_turn if net_driven else Input.get_axis("move_right", "move_left")
	var boosting := net_boost if net_driven else Input.is_action_pressed("sprint")
	if Engine.get_physics_frames() <= _enter_frame + 1:
		gas = 0.0
		turn = 0.0
	_tick_turbo(delta, absf(gas) if boosting else 0.0, _speed)
	var max_speed := lerpf(MAX_SPEED, BOOST_SPEED, boost)
	var accel := lerpf(ACCEL, BOOST_ACCEL, boost)
	_speed = clampf(_speed + gas * accel * delta, REV_LIMIT, max_speed)
	if absf(_speed) > 0.5:
		_steer = move_toward(_steer, turn, delta * 5.0)
		rotation.y += _steer * TURN * delta * clampf(_speed / max_speed, -1.0, 1.0)
	else:
		_steer = move_toward(_steer, 0.0, delta * 4.0)
	velocity = transform.basis.z * _speed
	if not is_on_floor():
		velocity.y -= 24.0 * delta
	move_and_slide()
	if net_driven:
		return
	var dir := transform.basis.z
	_cam.look_at(global_position + dir * 3.5 + Vector3(0.0, 1.0, 0.0), Vector3.UP)


func _ghost_physics(delta: float) -> void:
	var k := clampf(delta * 12.0, 0.0, 1.0)
	var target: Vector3 = get_meta("net_target", global_position)
	var moved := global_position.distance_to(target)
	global_position = global_position.lerp(target, k)
	rotation.y = lerp_angle(rotation.y, float(get_meta("net_rot", rotation.y)), k)
	_est_speed = lerpf(_est_speed, moved / maxf(delta, 0.0001), clampf(delta * 5.0, 0.0, 1.0))
	if _is_local_driver():
		var gas := Input.get_axis("move_back", "move_forward")
		var boosting := Input.is_action_pressed("sprint")
		_tick_turbo(delta, absf(gas) if boosting else 0.0, _est_speed)
		_fov = lerpf(_fov, 68.0 + boost * 20.0, clampf(delta * 6.0, 0.0, 1.0))
		_cam.fov = _fov
		_cam.current = true
		var dir := transform.basis.z
		_cam.look_at(global_position + dir * 3.5 + Vector3(0.0, 1.0, 0.0), Vector3.UP)


func _process(delta: float) -> void:
	if world == null or not bool(world.get("_client")):
		return
	_blowoff = maxf(0.0, _blowoff - delta / 0.45)
	if _is_local_driver():
		_fill_audio()
	else:
		_engine_audio.playing = false
		_turbo_audio.playing = false
		boost = 0.0
		_spool = 0.0


func _fill_audio() -> void:
	if not _engine_audio.playing:
		_engine_audio.play()
	if not _turbo_audio.playing:
		_turbo_audio.play()
	var epb: AudioStreamGeneratorPlayback = _engine_audio.get_stream_playback()
	var tpb: AudioStreamGeneratorPlayback = _turbo_audio.get_stream_playback()
	if epb == null or tpb == null:
		return
	var rpm_n := clampf(_rpm, 0.0, 1.0)
	var step := TAU / 22050.0
	var base := 55.0 + rpm_n * 160.0
	var eframes := epb.get_frames_available()
	for i in eframes:
		_e_phase += step * base
		var s := sin(_e_phase) * 0.3 + sin(_e_phase * 2.0) * 0.15 + sin(_e_phase * 0.5) * 0.18
		_noise_sm = _noise_sm * 0.9 + randf_range(-1.0, 1.0) * 0.1
		s += _noise_sm * (0.04 + 0.07 * rpm_n)
		s *= 0.7
		epb.push_frame(Vector2(s, s))
	var tframes := tpb.get_frames_available()
	var whine_f := 750.0 + rpm_n * 500.0 + boost * 1800.0
	var whine_amp := 0.05 + boost * 0.25
	var spool_noise := _spool * 0.3
	var blow := _blowoff
	for i in tframes:
		_t_phase += step * whine_f
		var s := sin(_t_phase) * whine_amp
		_noise_sm2 = _noise_sm2 * 0.75 + randf_range(-1.0, 1.0) * 0.25
		s += _noise_sm2 * spool_noise
		if blow > 0.01:
			var bfreq := 1800.0 - blow * 1500.0
			_b_phase += step * bfreq
			s += sin(_b_phase) * 0.6 * blow
			s += randf_range(-1.0, 1.0) * 0.3 * blow
		s *= 0.6
		tpb.push_frame(Vector2(s, s))


func set_player(p: CharacterBody3D) -> void:
	_player_in = p
