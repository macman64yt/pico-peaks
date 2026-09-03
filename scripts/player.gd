extends CharacterBody3D

var world: Node

signal stats_changed(health: float, stamina: float, thirst: float)
signal died
signal shot_fired(origin: Vector3, end: Vector3)
signal damaged
signal crime_committed(pos: Vector3)

@export var walk_speed := 6.0
@export var sprint_speed := 11.0
@export var jump_velocity := 6.8
@export var mouse_sens := 0.0021
@export var accel := 11.0
@export var gravity := 24.0

@export var max_health := 100.0
@export var max_stamina := 100.0
@export var max_thirst := 100.0
@export var stamina_drain := 22.0
@export var stamina_regen := 16.0
@export var thirst_drain := 2.2
@export var dehydration_damage := 3.0
@export var fall_damage_start := 14.0
@export var fall_damage_factor := 5.0

@onready var arm: SpringArm3D = $CameraRig
@onready var camera: Camera3D = $CameraRig/Camera
@onready var headlamp: SpotLight3D = $CameraRig/Camera/Headlamp

var _punch_sfx: AudioStreamPlayer3D

var _yaw := 0.0
var _pitch := 0.0
var _third_person := false
var _lamp_on := true
var lamp_battery := 1.0
var _lamp_warned := false
var _bob_t := 0.0
var _cam_origin_y := 0.12
var _fall_v := 0.0
var _fov_base := 0.0
var _fov_cur := 0.0
var _step_t := 0.0
var _dust: GPUParticles3D
var health := 100.0
var stamina := 100.0
var thirst := 100.0
var _dehydrate_t := 0.0
var invert_y := false
var ammo := 12
var max_ammo := 12
var reserve_ammo := 24
var has_gun := false
var has_grapple := false
var _grapple_target := Vector3.ZERO
var _grapple_pull := 0.0
var _grapple_cooldown := 0.0
var in_car := false
var in_boat := false
var in_car_id := -1
var hazmat := false
var _reload_timer := 0.0
var _freeze := false
var _punch_t := 0.0
var _gun: Node3D
var _gun_flash: OmniLight3D
var _flash_quad: MeshInstance3D
var _muzzle: Marker3D
var _punch_arm: MeshInstance3D
var _player_body: Node3D
var net_controlled := false
var net_slave := false
var net_input: Dictionary = {}
var net_yaw := 0.0
var net_pitch := 0.0
var _net_input_t := 0.0
var touch_mode := false
var touch_move_vec := Vector2.ZERO

func _ready() -> void:
	if net_controlled:
		return
	if not touch_mode:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_cam_origin_y = 0.12
	_build_player_body()
	var body_mesh := get_node_or_null("Body")
	if body_mesh:
		body_mesh.visible = false
	_build_punch_sfx()
	_build_punch_arm()

func _unhandled_input(event: InputEvent) -> void:
	if net_controlled:
		return
	if in_car or _chat_open():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_yaw -= event.relative.x * mouse_sens
		var flip := -1.0 if invert_y else 1.0
		_pitch = clampf(_pitch - event.relative.y * mouse_sens * flip, -1.45, 1.45)
		_apply_rot()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				if has_gun:
					_shoot()
				else:
					_punch()
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event.is_action_pressed("reload"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED or touch_mode:
			_start_reload()
	elif event.is_action_pressed("grapple"):
		if not in_car and not _chat_open():
			_try_grapple()
	elif event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _apply_rot() -> void:
	arm.rotation = Vector3(_pitch, 0.0, 0.0)
	rotation.y = _yaw


func touch_look(dx: float, dy: float) -> void:
	if net_controlled or net_slave or in_car or _chat_open():
		return
	_yaw -= dx * mouse_sens
	var flip := -1.0 if invert_y else 1.0
	_pitch = clampf(_pitch - dy * mouse_sens * flip, -1.45, 1.45)
	_apply_rot()

func _chat_open() -> bool:
	var chat := get_tree().get_first_node_in_group("chat")
	if chat != null and chat.is_open():
		return true
	var console := get_tree().get_first_node_in_group("console")
	return console != null and console.is_open()

func _build_gun() -> void:
	_gun = Node3D.new()
	_gun.name = "Gun"
	_gun.position = Vector3(0.18, -0.16, -0.34)
	camera.add_child(_gun)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.16, 0.17, 0.20)
	body_mat.roughness = 0.6
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.05, 0.11, 0.26)
	body.mesh = bm
	body.material_override = body_mat
	_gun.add_child(body)
	var barrel := MeshInstance3D.new()
	var bm2 := BoxMesh.new()
	bm2.size = Vector3(0.026, 0.026, 0.18)
	barrel.mesh = bm2
	barrel.position = Vector3(0.0, 0.005, -0.21)
	barrel.material_override = body_mat
	_gun.add_child(barrel)
	var stock_mat := StandardMaterial3D.new()
	stock_mat.albedo_color = Color(0.3, 0.22, 0.14)
	stock_mat.roughness = 0.7
	var stock := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(0.045, 0.1, 0.16)
	stock.mesh = sm
	stock.material_override = stock_mat
	stock.position = Vector3(0.0, 0.01, 0.17)
	_gun.add_child(stock)
	var guard := MeshInstance3D.new()
	var gm := CylinderMesh.new()
	gm.top_radius = 0.02
	gm.bottom_radius = 0.02
	gm.height = 0.12
	guard.mesh = gm
	var guard_mat := StandardMaterial3D.new()
	guard_mat.albedo_color = Color(0.08, 0.08, 0.1)
	guard_mat.roughness = 0.5
	guard.material_override = guard_mat
	guard.position = Vector3(0.0, 0.005, -0.12)
	_gun.add_child(guard)
	var sight := MeshInstance3D.new()
	var sitm := BoxMesh.new()
	sitm.size = Vector3(0.008, 0.02, 0.03)
	sight.mesh = sitm
	sight.material_override = body_mat
	sight.position = Vector3(0.0, 0.07, -0.1)
	_gun.add_child(sight)
	var mag := MeshInstance3D.new()
	var mgm := BoxMesh.new()
	mgm.size = Vector3(0.03, 0.1, 0.04)
	mag.mesh = mgm
	mag.material_override = body_mat
	mag.position = Vector3(0.0, -0.06, -0.02)
	mag.rotation.x = -0.15
	_gun.add_child(mag)
	_muzzle = Marker3D.new()
	_muzzle.name = "Muzzle"
	_muzzle.position = Vector3(0.0, 0.005, -0.30)
	_gun.add_child(_muzzle)
	_gun_flash = OmniLight3D.new()
	_gun_flash.light_color = Color(1.0, 0.9, 0.5)
	_gun_flash.light_energy = 0.0
	_gun_flash.omni_range = 8.0
	_gun_flash.position = Vector3(0.0, 0.01, -0.34)
	_gun.add_child(_gun_flash)
	_flash_quad = MeshInstance3D.new()
	var fm := QuadMesh.new()
	fm.size = Vector2(0.28, 0.28)
	_flash_quad.mesh = fm
	var fm_mat := StandardMaterial3D.new()
	fm_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm_mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fm_mat.albedo_color = Color(1.0, 0.85, 0.4, 1.0)
	_flash_quad.material_override = fm_mat
	_flash_quad.position = Vector3(0.0, 0.01, -0.36)
	_flash_quad.visible = false
	_gun.add_child(_flash_quad)

func _shoot() -> void:
	if net_slave:
		if not _chat_open() and _world_net_ready():
			world._sv_shoot.rpc_id(1)
		return
	if _reload_timer > 0.0 or _freeze or not has_gun:
		return
	if ammo <= 0:
		_start_reload()
		return
	ammo -= 1
	_pitch = clampf(_pitch + randf_range(0.01, 0.02), -1.45, 1.45)
	_apply_rot()
	_gun.position.z = -0.34 + 0.07
	_gun.rotation.x = randf_range(-0.03, 0.03)
	_gun_flash.light_energy = 3.0
	_flash_quad.visible = true
	var from := _muzzle.global_position if _muzzle else camera.global_position
	var dir := -camera.global_transform.basis.z
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 120.0, 1 | 2)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var end := from + dir * 120.0
	if hit:
		end = hit.position
		var collider: Object = hit.collider
		if collider is Node and collider.has_method("hit"):
			collider.hit(2)
		if collider is Node and (collider as Node).is_in_group("npc"):
			crime_committed.emit(global_position)
	shot_fired.emit(from, end)
	if ammo <= 0:
		_start_reload()

func _start_reload() -> void:
	if net_slave:
		if _world_net_ready():
			world._sv_reload.rpc_id(1)
		return
	if _reload_timer > 0.0 or ammo == max_ammo or reserve_ammo <= 0:
		return
	_reload_timer = 1.2

func _try_grapple() -> void:
	if not has_grapple:
		return
	if _grapple_cooldown > 0.0 or _freeze or _punch_t > 0.0:
		return
	if net_slave:
		return
	var range_max := 60.0
	var from := camera.global_position
	var dir := -camera.global_transform.basis.z
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * range_max, 1 | 2 | 4)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	if not hit:
		if world and world.has_method("_post_chat"):
			world._post_chat("You", "Your grapple hook finds no purchase.")
		_grapple_cooldown = 0.6
		return
	var tgt: Vector3 = hit.position
	_grapple_target = tgt
	_grapple_pull = 0.35
	_grapple_cooldown = 1.1
	if _punch_sfx != null:
		_punch_sfx.stream = _make_whoosh_wav()
		_punch_sfx.pitch_scale = 1.5
		_punch_sfx.play()


func _punch() -> void:
	if net_slave:
		if not _chat_open() and _world_net_ready():
			world._sv_punch.rpc_id(1)
			var q2 := PhysicsRayQueryParameters3D.create(camera.global_position,
				camera.global_position - camera.global_transform.basis.z * 2.6, 1 | 2)
			q2.exclude = [get_rid()]
			_play_punch(get_world_3d().direct_space_state.intersect_ray(q2) != {})
		return
	if _freeze or _punch_t > 0.0:
		return
	_punch_t = 0.18
	_play_punch(false)
	var from := camera.global_position
	var dir := -camera.global_transform.basis.z
	var q := PhysicsRayQueryParameters3D.create(from, from + dir * 2.6, 1 | 2)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var ray_collider: Object = null
	if hit:
		ray_collider = hit.collider
		if ray_collider is Node:
			var cn := ray_collider as Node
			if cn.has_method("hit"):
				cn.hit(2)
			if cn.has_method("punched"):
				cn.punched()
			if cn.is_in_group("npc"):
				crime_committed.emit(global_position)
			_play_punch(true)
	for z in get_tree().get_nodes_in_group("zombies"):
		if z == ray_collider:
			continue
		var zn := z as Node3D
		if zn == null or not is_instance_valid(zn):
			continue
		if bool(zn.get("_dead")):
			continue
		var to_z := zn.global_position - global_position
		to_z.y = 0.0
		if to_z.length() > 2.2:
			continue
		if to_z.normalized().dot(dir) < 0.3:
			continue
		if zn.has_method("hit"):
			zn.hit(2)
	_pitch = clampf(_pitch + 0.02, -1.45, 1.45)
	_apply_rot()

func arm_gun() -> void:
	if has_gun:
		return
	has_gun = true
	_build_gun()
	ammo = max_ammo
	_reload_timer = 0.0


func _play_punch(hit: bool) -> void:
	if _punch_sfx == null:
		return
	_punch_sfx.stream = _make_thwack_wav() if hit else _make_whoosh_wav()
	_punch_sfx.play()


func _build_punch_sfx() -> void:
	_punch_sfx = AudioStreamPlayer3D.new()
	_punch_sfx.max_db = 2.0
	_punch_sfx.unit_size = 8.0
	_punch_sfx.volume_db = -6.0
	add_child(_punch_sfx)


func _make_whoosh_wav() -> AudioStreamWAV:
	var rate := 16000
	var frames := int(rate * 0.12)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var lp := 0.0
	for i in frames:
		var t := float(i) / float(frames)
		var s := randf() * 2.0 - 1.0
		lp = lerpf(lp, s, 0.4)
		var sample := int(clampf(lp * (1.0 - t * 0.7), -1.0, 1.0) * 32767.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav


func _make_thwack_wav() -> AudioStreamWAV:
	var rate := 22050
	var frames := int(rate * 0.16)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var lp := 0.0
	var phase := 0.0
	for i in frames:
		var t := float(i) / float(frames)
		var decay := pow(1.0 - t, 1.8)
		var noise := (randf() * 2.0 - 1.0) * decay
		lp = lerpf(lp, noise, 0.55)
		phase += 0.35
		var thump := sin(phase) * decay * 0.7
		var sample := int(clampf(lp * 0.9 + thump, -1.0, 1.0) * 32767.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	return wav


func _build_player_body() -> void:
	if _player_body != null:
		return
	_player_body = Node3D.new()
	_player_body.name = "Body"
	var jacket := StandardMaterial3D.new()
	jacket.albedo_color = Color(0.16, 0.18, 0.22)
	jacket.roughness = 0.7
	var jacket_dark := StandardMaterial3D.new()
	jacket_dark.albedo_color = Color(0.1, 0.12, 0.15)
	jacket_dark.roughness = 1.0
	var skin := StandardMaterial3D.new()
	skin.albedo_color = Color(0.92, 0.74, 0.6)
	skin.roughness = 0.7
	var hair := StandardMaterial3D.new()
	hair.albedo_color = Color(0.16, 0.12, 0.09)
	hair.roughness = 0.9
	var pants := StandardMaterial3D.new()
	pants.albedo_color = Color(0.13, 0.13, 0.16)
	pants.roughness = 0.9
	var boot := StandardMaterial3D.new()
	boot.albedo_color = Color(0.14, 0.1, 0.08)
	boot.roughness = 0.8
	var torso := MeshInstance3D.new()
	var tm := BoxMesh.new()
	tm.size = Vector3(0.46, 0.52, 0.28)
	torso.mesh = tm
	torso.material_override = jacket
	torso.position = Vector3(0.0, 1.12, 0.0)
	_player_body.add_child(torso)
	var belt := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.48, 0.1, 0.3)
	belt.mesh = bm
	belt.material_override = jacket_dark
	belt.position = Vector3(0.0, 0.9, 0.0)
	_player_body.add_child(belt)
	var pelvis := MeshInstance3D.new()
	var pm := BoxMesh.new()
	pm.size = Vector3(0.4, 0.2, 0.24)
	pelvis.mesh = pm
	pelvis.material_override = jacket_dark
	pelvis.position = Vector3(0.0, 0.78, 0.0)
	_player_body.add_child(pelvis)
	var arm_mesh := CapsuleMesh.new()
	arm_mesh.radius = 0.06
	arm_mesh.height = 0.5
	for sx in [-0.28, 0.28]:
		var arm := MeshInstance3D.new()
		arm.mesh = arm_mesh
		arm.material_override = jacket
		arm.position = Vector3(sx * 0.82, 1.16, 0.0)
		_player_body.add_child(arm)
		var hand := MeshInstance3D.new()
		var hm2 := SphereMesh.new()
		hm2.radius = 0.055
		hm2.height = 0.1
		hand.mesh = hm2
		hand.material_override = skin
		hand.position = Vector3(sx * 0.84, 0.9, 0.0)
		_player_body.add_child(hand)
	var leg_mesh := CapsuleMesh.new()
	leg_mesh.radius = 0.09
	leg_mesh.height = 0.72
	for sx in [-0.13, 0.13]:
		var leg := MeshInstance3D.new()
		leg.mesh = leg_mesh
		leg.material_override = pants
		leg.position = Vector3(sx, 0.4, 0.0)
		_player_body.add_child(leg)
		var foot := MeshInstance3D.new()
		var fm := BoxMesh.new()
		fm.size = Vector3(0.16, 0.08, 0.28)
		foot.mesh = fm
		foot.material_override = boot
		foot.position = Vector3(sx, 0.05, 0.05)
		_player_body.add_child(foot)
	var head := MeshInstance3D.new()
	var hsm := SphereMesh.new()
	hsm.radius = 0.15
	hsm.height = 0.28
	head.mesh = hsm
	head.material_override = skin
	head.position = Vector3(0.0, 1.52, 0.0)
	_player_body.add_child(head)
	var hair_cap := MeshInstance3D.new()
	var hcm := SphereMesh.new()
	hcm.radius = 0.16
	hcm.height = 0.18
	hair_cap.mesh = hcm
	hair_cap.material_override = hair
	hair_cap.position = Vector3(0.0, 1.58, -0.02)
	hair_cap.scale.y = 0.7
	_player_body.add_child(hair_cap)
	add_child(_player_body)


func _build_punch_arm() -> void:
	_punch_arm = MeshInstance3D.new()
	_punch_arm.name = "PunchArm"
	var sleeve_mat := StandardMaterial3D.new()
	sleeve_mat.albedo_color = Color(0.16, 0.18, 0.22)
	sleeve_mat.roughness = 0.7
	var glove_mat := StandardMaterial3D.new()
	glove_mat.albedo_color = Color(0.35, 0.24, 0.18)
	glove_mat.roughness = 0.8
	var forearm := MeshInstance3D.new()
	var fam := CapsuleMesh.new()
	fam.radius = 0.045
	fam.height = 0.26
	forearm.mesh = fam
	forearm.material_override = sleeve_mat
	forearm.position = Vector3(0.0, -0.05, -0.24)
	_punch_arm.add_child(forearm)
	var fist := MeshInstance3D.new()
	var fistm := SphereMesh.new()
	fistm.radius = 0.07
	fistm.height = 0.12
	fist.mesh = fistm
	fist.material_override = glove_mat
	fist.position = Vector3(0.0, -0.05, -0.42)
	_punch_arm.add_child(fist)
	_punch_arm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_punch_arm.position = Vector3(0.18, -0.16, -0.34)
	_punch_arm.visible = false
	camera.add_child(_punch_arm)

func strip_gun() -> void:
	if _gun:
		_gun.queue_free()
		_gun = null
	_muzzle = null
	_gun_flash = null
	_flash_quad = null
	has_gun = false
	ammo = 0
	reserve_ammo = 0
	_reload_timer = 0.0

func hit(dmg: int) -> void:
	if _freeze or in_car or health <= 0.0:
		return
	health = maxf(0.0, health - dmg)
	damaged.emit()
	stats_changed.emit(health, stamina, thirst)
	if health <= 0.0:
		died.emit()

func _tick_gun(delta: float) -> void:
	if _reload_timer > 0.0:
		_reload_timer = maxf(0.0, _reload_timer - delta)
		if _reload_timer == 0.0:
			var need := max_ammo - ammo
			var take := mini(need, reserve_ammo)
			ammo += take
			reserve_ammo -= take
	if not _gun:
		return
	_gun.position.z = move_toward(_gun.position.z, -0.34, delta * 8.0)
	_gun.rotation.x = move_toward(_gun.rotation.x, 0.0, delta * 8.0)
	_gun_flash.light_energy = maxf(0.0, _gun_flash.light_energy - delta * 14.0)
	if _flash_quad.visible and _gun_flash.light_energy <= 0.2:
		_flash_quad.visible = false

func _physics_process(delta: float) -> void:
	if net_controlled:
		_net_server_physics(delta)
		return
	if net_slave:
		_net_client_physics(delta)
		return
	if in_car:
		return
	if _chat_open() or _freeze:
		if not is_on_floor():
			velocity.y -= gravity * delta
		else:
			velocity.y = 0.0
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return
	_tick_gun(delta)
	if touch_mode and Input.is_action_just_pressed("shoot"):
		if has_gun:
			_shoot()
		else:
			_punch()
	if touch_mode and Input.is_action_just_pressed("reload"):
		_start_reload()
	var input: Vector2
	if touch_mode:
		input = touch_move_vec
	else:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var dir := (transform.basis * Vector3(input.x, 0.0, input.y))
	if not touch_mode:
		dir = dir.normalized()

	var sprinting := Input.is_action_pressed("sprint") and stamina > 1.0
	if sprinting:
		stamina = maxf(0.0, stamina - stamina_drain * delta)
	else:
		stamina = minf(max_stamina, stamina + stamina_regen * delta)
	thirst = maxf(0.0, thirst - (thirst_drain * delta) * (1.5 if sprinting else 1.0))
	if thirst <= 0.0:
		_dehydrate_t += delta
		if _dehydrate_t >= 1.0:
			_dehydrate_t = 0.0
			health = maxf(0.0, health - dehydration_damage)
			if health <= 0.0:
				died.emit()
	var speed := sprint_speed if sprinting else walk_speed
	var target := dir * speed

	if touch_mode or Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		velocity.x = move_toward(velocity.x, target.x, accel * delta)
		velocity.z = move_toward(velocity.z, target.z, accel * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, accel * delta)
		velocity.z = move_toward(velocity.z, 0.0, accel * delta)

	if not is_on_floor():
		velocity.y -= gravity * delta
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
	if _grapple_cooldown > 0.0:
		_grapple_cooldown = maxf(0.0, _grapple_cooldown - delta)
	if _grapple_pull > 0.0:
		_grapple_pull = maxf(0.0, _grapple_pull - delta)
		var pull_dir := (_grapple_target - global_position).normalized()
		velocity = velocity.lerp(pull_dir * 26.0, clampf(delta * 6.0, 0.0, 1.0))
		velocity.y = maxf(velocity.y, 6.0)
	move_and_slide()

	if not is_on_floor():
		_fall_v = minf(_fall_v, velocity.y)
	else:
		if _fall_v < -fall_damage_start:
			var dmg := (-_fall_v - fall_damage_start) * fall_damage_factor
			health = maxf(0.0, health - dmg)
			if health <= 0.0:
				died.emit()
		_fall_v = 0.0

	if Input.is_action_just_pressed("view_toggle"):
		_third_person = not _third_person
		_apply_view()
	if Input.is_action_just_pressed("light_toggle"):
		if not _lamp_on and lamp_battery <= 0.0:
			_lamp_on = false
		else:
			_lamp_on = not _lamp_on
		headlamp.visible = _lamp_on
	if _lamp_on:
		lamp_battery = maxf(0.0, lamp_battery - delta / 240.0)
		if lamp_battery <= 0.0:
			_lamp_on = false
			headlamp.visible = false
			if not _lamp_warned and world and world.has_method("_post_chat"):
				_lamp_warned = true
				world._post_chat("System", "Flashlight battery dead — find a charger.")
		headlamp.light_energy = 2.8 if lamp_battery > 0.25 else (1.2 if fmod(Time.get_ticks_msec() / 1000.0 * 9.0, 1.0) > 0.25 else 0.2)
	else:
		headlamp.light_energy = 2.8

	var hspeed := Vector2(velocity.x, velocity.z).length()
	if _fov_base <= 0.0:
		_fov_base = camera.fov
	var kick := 9.0 if (sprinting and hspeed > 6.0) else 0.0
	_fov_cur = lerpf(_fov_cur, _fov_base + kick, clampf(delta * 8.0, 0.0, 1.0))
	camera.fov = _fov_cur
	if is_on_floor() and hspeed > 3.0 and not in_car:
		_step_t -= delta
		if _step_t <= 0.0:
			_step_t = 0.4 / maxf(0.6, hspeed / walk_speed)
			_puff_dust()
	else:
		_step_t = 0.0

	if _third_person:
		stats_changed.emit(health, stamina, thirst)
		return
	if _punch_t > 0.0:
		_punch_t -= delta
	if is_on_floor() and hspeed > 1.5:
		_bob_t += delta * hspeed * 0.55
		var bob := sin(_bob_t) * 0.028
		camera.position.y = _cam_origin_y + bob
	else:
		_bob_t = 0.0
		camera.position.y = move_toward(camera.position.y, _cam_origin_y, delta * 3.0)
	var lunge := 0.0
	if _punch_t > 0.0:
		lunge = sin((0.18 - _punch_t) / 0.18 * PI) * 0.06
	camera.position.z = move_toward(camera.position.z, lunge, delta * 6.0)
	if _punch_arm:
		if _punch_t > 0.0:
			var ph := (0.18 - _punch_t) / 0.18
			var swing := sin(ph * PI)
			_punch_arm.visible = true
			_punch_arm.position.z = -0.34 - swing * 0.38
			_punch_arm.rotation.x = swing * -0.55
		else:
			_punch_arm.visible = false
			_punch_arm.position.z = -0.34
			_punch_arm.rotation.x = 0.0
	stats_changed.emit(health, stamina, thirst)

func _world_net_ready() -> bool:
	if world == null or not bool(world.get("_world_ready")):
		return false
	var peer := multiplayer.multiplayer_peer
	if peer is ENetMultiplayerPeer:
		return peer.get_connection_status() == ENetMultiplayerPeer.CONNECTION_CONNECTED
	return multiplayer.is_server()

func _net_server_physics(delta: float) -> void:
	if in_car:
		return
	_tick_gun(delta)
	var m: Vector2 = net_input.get("move", Vector2.ZERO)
	var dir := (transform.basis * Vector3(m.x, 0.0, m.y)).normalized()
	var sprint := bool(net_input.get("sprint", false))
	var speed := sprint_speed if sprint else walk_speed
	var target := dir * speed
	velocity.x = move_toward(velocity.x, target.x, accel * delta)
	velocity.z = move_toward(velocity.z, target.z, accel * delta)
	if not is_on_floor():
		velocity.y -= gravity * delta
	if bool(net_input.get("jump", false)) and is_on_floor():
		velocity.y = jump_velocity
	move_and_slide()
	rotation.y = net_yaw
	if not is_on_floor():
		_fall_v = minf(_fall_v, velocity.y)
	else:
		if _fall_v < -fall_damage_start:
			var dmg := (-_fall_v - fall_damage_start) * fall_damage_factor
			health = maxf(0.0, health - dmg)
			if health <= 0.0:
				died.emit()
		_fall_v = 0.0

func _net_client_physics(delta: float) -> void:
	_net_input_t -= delta
	if in_car:
		_net_send_car_input()
		return
	_tick_gun(delta)
	_apply_rot()
	var input: Vector2
	if touch_mode:
		input = touch_move_vec
	else:
		input = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	if _net_input_t <= 0.0 and _world_net_ready():
		_net_input_t = 1.0 / 15.0
		world._sv_player_input.rpc_id(1, input.x, input.y,
			Input.is_action_pressed("sprint") and stamina > 1.0,
			Input.is_action_just_pressed("jump") and is_on_floor(), _yaw, _pitch)
	if Input.is_action_pressed("sprint") and stamina > 1.0 and input.length() > 0.1:
		stamina = maxf(0.0, stamina - stamina_drain * delta)
	else:
		stamina = minf(max_stamina, stamina + stamina_regen * delta)
	velocity.y -= gravity * delta
	move_and_slide()
	stats_changed.emit(health, stamina, thirst)

func _net_send_car_input() -> void:
	if bool(get("in_boat")):
		_net_send_boat_input()
		return
	var cidx: int = int(get("in_car_id"))
	if cidx < 0 or not _world_net_ready():
		return
	if _net_input_t > 0.0:
		return
	_net_input_t = 1.0 / 15.0
	var gas := Input.get_axis("move_back", "move_forward")
	var turn := Input.get_axis("move_right", "move_left")
	var boost := Input.is_action_pressed("sprint")
	world._sv_car_input.rpc_id(1, cidx, gas, turn, boost)


func _net_send_boat_input() -> void:
	if not _world_net_ready():
		return
	if _net_input_t > 0.0:
		return
	_net_input_t = 1.0 / 15.0
	var gas := Input.get_axis("move_back", "move_forward")
	var turn := Input.get_axis("move_right", "move_left")
	world._sv_boat_input.rpc_id(1, gas, turn)

func respawn(pos: Vector3) -> void:
	health = max_health
	stamina = max_stamina
	_fall_v = 0.0
	global_position = pos
	velocity = Vector3.ZERO
	stats_changed.emit(health, stamina, thirst)

func _apply_view() -> void:
	if _third_person:
		arm.spring_length = 4.8
		camera.position = Vector3(0.0, 1.1, 0.0)
	else:
		arm.spring_length = 0.0
		camera.position = Vector3(0.0, _cam_origin_y, 0.0)
	if _gun:
		_gun.visible = not _third_person
	var body_mesh := get_node_or_null("Body")
	if body_mesh:
		body_mesh.visible = _third_person


func _puff_dust() -> void:
	if _dust == null:
		_dust = GPUParticles3D.new()
		_dust.one_shot = true
		_dust.amount = 7
		_dust.lifetime = 0.55
		_dust.explosiveness = 1.0
		var mat := ParticleProcessMaterial.new()
		mat.direction = Vector3(0.0, 1.0, 0.0)
		mat.spread = 45.0
		mat.gravity = Vector3(0.0, -1.5, 0.0)
		mat.initial_velocity_min = 0.4
		mat.initial_velocity_max = 1.3
		mat.damping_min = 2.0
		mat.damping_max = 4.5
		mat.scale_min = 0.05
		mat.scale_max = 0.13
		_dust.process_material = mat
		var trail := Gradient.new()
		trail.set_color(0, Color(0.55, 0.5, 0.4, 0.5))
		trail.set_color(1, Color(0.55, 0.5, 0.4, 0.0))
		_dust.color_ramp = trail
		_dust.position = Vector3(0.0, 0.06, 0.0)
		add_child(_dust)
	_dust.restart()