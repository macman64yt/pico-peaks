extends CharacterBody3D

var world: Node

var _home := Vector3.ZERO
var _target := Vector3.ZERO
var _speed := 1.3
var _pause := 0.0
var _t := 0.0
var _was_night := false
var _was_storm := false
var _retiring := false
var _inside := false
var _bed_entry := Vector3.ZERO
var _bed_spot := Vector3.ZERO
var _robe: MeshInstance3D
var _robe_mat: StandardMaterial3D
var _base_color := Color.WHITE
var _flash := 0.0
var _dead := false
var _aggro := false
var _afraid := false
var _gun_out := false
var _shoot_timer := 0.0
var _gun: Node3D
var _gun_flash: OmniLight3D
var has_gun := false
var is_child := false
var is_police := false
var is_worker := false
var hp := 6
var _warn_timer := 0.0
var _warned := false
var _panicked := false
var _name := ""
var _name_label: Label3D
var _hp_fg: Node3D
var _chat_t := 0.0
var _fishing := false
var _fishing_spot := Vector3.ZERO
var _rod: MeshInstance3D

var interact_hint := "[E] Talk"

const NAMES := ["Aiko", "Kenji", "Mika", "Yuki", "Hiro", "Sora"]
const LINES := [
	"The mountains sing tonight.",
	"Be careful on the high peaks.",
	"The old shrine is just to the east.",
	"This world changes with every seed.",
	"I heard a strange sound near the water.",
	"The winters here are beautiful.",
	"They say the houses have beds now.",
	"The hot spring steams all year. Good for what aches you.",
	"The bell tolls every hour on the hour. You'll learn to live with it.",
	"Cat keeps following me around the village. Named it after my uncle.",
	"A balloon drifts over the peaks some days. Nobody knows whose it is.",
	"Storm's coming? You'll see the dogs bolt for cover first.",
	"Try the dock at dusk — the fish bite best then.",
	"Good fishing tonight. Patience is all it takes.",
]
const SHOUTS := [
	"You'll pay for that!",
	"Get back!",
	"Stay away!",
	"That's it, you asked for it!",
]
const WORKER_LINES := [
	"Rods at 70 percent, coolant steady.",
	"Watch the core temp — she runs hot this time of day.",
	"Don't touch the rods unless you're trained.",
	"Steam turbine at full spin. Listen to her whine.",
	"Demand's climbing. The grid wants more juice.",
	"Keep an eye on that SCRAM switch.",
	"Maintenance window opens at dawn.",
	"That red beacon on the tower? Keeps the planes off the mountain.",
	"Rain's good — fills the catchment ponds for the coolant.",
	"Wind over fifty-five percent and the blades furl themselves. Clever old machines.",
	"Zombies in the valley tonight? Bolt the gates and ride it out.",
]
const WORKER_NAMES := ["Tech", "Engineer", "Operator", "Control Room"]

var net_slave := false

func display_name() -> String:
	if _name != "":
		return _name
	return NAMES[randi() % NAMES.size()]

func random_line() -> String:
	if is_worker:
		return WORKER_LINES[randi() % WORKER_LINES.size()]
	return LINES[randi() % LINES.size()]

func say_line() -> void:
	if world and world.has_method("_post_chat"):
		world._post_chat(_name, random_line())

func interact() -> void:
	say_line()

func _ready() -> void:
	_home = global_position
	_name = NAMES[randi() % NAMES.size()]
	if is_worker:
		_name = "%s %s" % [WORKER_NAMES[randi() % WORKER_NAMES.size()], _name]
		for c in get_children():
			if c is MeshInstance3D:
				var m := (c as MeshInstance3D).mesh
				if m is BoxMesh and (m as BoxMesh).size == Vector3(0.4, 0.12, 0.4):
					var hm := StandardMaterial3D.new()
					hm.albedo_color = Color(0.95, 0.78, 0.1)
					hm.roughness = 0.4
					(c as MeshInstance3D).material_override = hm
	if is_police:
		_name = "Officer %s" % _name
	for c in get_children():
		if c is MeshInstance3D:
			var m := (c as MeshInstance3D).mesh
			if m is BoxMesh and (m as BoxMesh).size == Vector3(0.66, 1.05, 0.42):
				_robe = c
				_robe_mat = _robe.material_override
				_base_color = _robe_mat.albedo_color
	if has_gun:
		_build_gun()
	_build_overhead()
	_build_rod()
	_pick_target()
	_was_night = world != null and world._is_night()
	_was_storm = world != null and int(world.get("_weather")) >= 3
	_chat_t = randf_range(6.0, 18.0)

func _physics_process(delta: float) -> void:
	if _dead:
		return
	if net_slave:
		_interpolate_slave(delta)
		return
	_update_robes(delta)
	_t -= delta
	_chat_t -= delta
	if _chat_t <= 0.0:
		_chat_t = randf_range(12.0, 40.0)
		if not _aggro and not _afraid and not _retiring:
			var pl: Node3D = world._ai_target(self) if world else null
			if pl and global_position.distance_to((pl as Node3D).global_position) < 18.0:
				say_line()
	velocity.y -= 24.0 * delta
	if _aggro:
		_do_aggro(delta)
		return
	if _afraid:
		_do_flee(delta)
		return
	var night: bool = world != null and bool(world._is_night())
	if not is_worker and night != _was_night:
		_was_night = night
		if night:
			_fishing = false
			if _rod:
				_rod.visible = false
			_find_house()
		else:
			_retiring = false
			_inside = false
			_panicked = false
			_fishing = false
			if _rod:
				_rod.visible = false
			if _bed_spot != Vector3.ZERO:
				global_position = _bed_entry
				_bed_spot = Vector3.ZERO
				_bed_entry = Vector3.ZERO
			_pick_target()
	var storm: bool = not is_worker and world != null and int(world.get("_weather")) >= 3
	if not is_worker and storm != _was_storm:
		_was_storm = storm
		if storm:
			if not _inside:
				_find_house()
		else:
			_retiring = false
			_inside = false
			_panicked = false
			if _bed_spot != Vector3.ZERO:
				global_position = _bed_entry
				_bed_spot = Vector3.ZERO
				_bed_entry = Vector3.ZERO
			_pick_target()
	if is_worker:
		_was_night = night
		_was_storm = false
	if _retiring:
		_do_retire(delta)
		return
	if _fishing:
		_do_fishing(delta)
		return
	if _pause > 0.0:
		_pause -= delta
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
		move_and_slide()
		return
	if _t <= 0.0:
		if not _try_fishing():
			_pick_target()
	var to := _target - global_position
	to.y = 0.0
	if to.length() < 0.4:
		_pause = randf_range(2.0, 6.0)
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
		move_and_slide()
		return
	var dir := to.normalized()
	velocity.x = move_toward(velocity.x, dir.x * _speed, 6.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * _speed, 6.0 * delta)
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 4.0)
	move_and_slide()

func _do_flee(delta: float) -> void:
	if _rod:
		_rod.visible = false
	var target: Node3D = world._ai_target(self) if world else null
	var spd := 1.7 if not is_child else 1.5
	if target:
		var to_p := (target as Node3D).global_position - global_position
		to_p.y = 0.0
		if to_p.length() > 28.0:
			_afraid = false
			_pick_target()
			velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
			move_and_slide()
			return
		var away := -to_p.normalized()
		velocity.x = move_toward(velocity.x, away.x * spd, 6.0 * delta)
		velocity.z = move_toward(velocity.z, away.z * spd, 6.0 * delta)
		rotation.y = lerp_angle(rotation.y, atan2(away.x, away.z), delta * 6.0)
	move_and_slide()

func _do_aggro(delta: float) -> void:
	if _rod:
		_rod.visible = false
	var target: Node3D = world._ai_target(self) if world else null
	if is_police:
		_do_police_chase(target, delta)
		return
	if _gun:
		_gun_flash.light_energy = maxf(0.0, _gun_flash.light_energy - delta * 10.0)
	if target:
		var to := (target as Node3D).global_position - global_position
		to.y = 0.0
		if to.length() > 60.0:
			_aggro = false
			_warned = false
			_pick_target()
			velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
			move_and_slide()
			return
		if to.length() > 0.01:
			rotation.y = lerp_angle(rotation.y, atan2(to.x, to.z), delta * 8.0)
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
		_shoot_timer -= delta
		if _shoot_timer <= 0.0:
			_shoot_timer = 1.2
			_fire_at(target)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
	move_and_slide()

func _do_police_chase(target: Node3D, delta: float) -> void:
	if _gun:
		_gun_flash.light_energy = maxf(0.0, _gun_flash.light_energy - delta * 10.0)
	if _warn_timer > 0.0:
		_warn_timer -= delta
		if not _warned and world and world.has_method("_post_chat"):
			_warned = true
			world._post_chat("Police", "Stop right there! Hands up!")
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
		if target:
			var f := (target as Node3D).global_position - global_position
			f.y = 0.0
			if f.length() > 0.01:
				rotation.y = lerp_angle(rotation.y, atan2(f.x, f.z), delta * 8.0)
		move_and_slide()
		return
	if target:
		var to := (target as Node3D).global_position - global_position
		to.y = 0.0
		if to.length() > 60.0:
			_aggro = false
			_warned = false
			_pick_target()
			velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
			velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
			move_and_slide()
			return
		if to.length() < 2.2:
			if world and world.has_method("_arrest_net_player") and world.has_method("_ai_target"):
				world._arrest_net_player(world._ai_target(self))
			return
		var dir := to.normalized()
		var spd := 5.0
		velocity.x = move_toward(velocity.x, dir.x * spd, 12.0 * delta)
		velocity.z = move_toward(velocity.z, dir.z * spd, 12.0 * delta)
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 8.0)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
	move_and_slide()

func _fire_at(target: Node3D) -> void:
	var muzzle := _gun_muzzle_global()
	var aim := (target as Node3D).global_position + Vector3(0.0, 1.4, 0.0)
	aim += Vector3(randf_range(-0.35, 0.35), randf_range(-0.25, 0.25), randf_range(-0.35, 0.35))
	var q := PhysicsRayQueryParameters3D.create(muzzle, aim, 1)
	q.exclude = [get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var end := aim
	if hit:
		end = hit.position
		if hit.collider is Node and (hit.collider as Node).get_meta("is_player", false) == true:
			if hit.collider.has_method("hit"):
				hit.collider.hit(3)
	if _gun_flash:
		_gun_flash.light_energy = 2.0
	if world and world.has_method("_spawn_tracer"):
		world._spawn_tracer(muzzle, end)

func _gun_muzzle_global() -> Vector3:
	if _gun:
		return _gun.global_position + _gun.global_transform.basis * Vector3(0.0, 0.0, -0.05)
	return global_position + Vector3(0.0, 1.4, -0.4)

func _do_retire(delta: float) -> void:
	if _rod:
		_rod.visible = false
	if _inside:
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
		move_and_slide()
		return
	var spd := _speed
	if _nearest_zombie(22.0) != null:
		spd = 3.4
		if not _panicked and world and world.has_method("_post_chat"):
			_panicked = true
			world._post_chat(display_name(), "Zombies! Run!")
	var to := _bed_entry - global_position
	to.y = 0.0
	if to.length() < 1.0:
		global_position = _bed_spot
		_inside = true
		velocity = Vector3.ZERO
		move_and_slide()
		return
	var dir := to.normalized()
	velocity.x = move_toward(velocity.x, dir.x * spd, 6.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * spd, 6.0 * delta)
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 4.0)
	move_and_slide()

func _find_house() -> void:
	var best: Node3D = null
	var best_d := INF
	for h in get_tree().get_nodes_in_group("houses"):
		var d: float = global_position.distance_to((h as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = h
	if best:
		_bed_entry = best.to_global(best.get_meta("entry_local"))
		_bed_spot = best.to_global(best.get_meta("interior_local"))
		_retiring = true
		_inside = false

func _nearest_zombie(radius: float) -> Node3D:
	var best: Node3D = null
	var best_d := radius
	for z in get_tree().get_nodes_in_group("zombies"):
		var d: float = global_position.distance_to((z as Node3D).global_position)
		if d < best_d:
			best_d = d
			best = z
	return best

func _pick_target() -> void:
	_t = randf_range(3.0, 7.0)
	_pause = 0.0
	var ang := randf() * TAU
	var r := randf_range(3.0, 24.0) if is_worker else randf_range(3.0, 12.0)
	_target = _home + Vector3(cos(ang) * r, 0.0, sin(ang) * r)


func _try_fishing() -> bool:
	if is_worker or is_police or is_child:
		return false
	if world == null or not world.has_method("_is_night") or bool(world._is_night()):
		return false
	if int(world.get("_weather")) >= 3:
		return false
	var tod := fmod(float(world.get("_time_of_day")), 24.0)
	if tod < 15.5 or tod > 20.5:
		return false
	if randi() % 3 != 0:
		return false
	var db: Vector3 = world.get("_dock_base")
	if db == Vector3.ZERO or global_position.distance_to(db) > 260.0:
		return false
	_fishing = true
	_fishing_spot = db + Vector3(cos(randf() * TAU), 0.0, sin(randf() * TAU)) * 3.0
	return true


func _do_fishing(delta: float) -> void:
	if _rod:
		_rod.visible = false
	if world == null or bool(world._is_night()) or int(world.get("_weather")) >= 3:
		_fishing = false
		_find_house()
		return
	if _pause > 0.0:
		_pause -= delta
		velocity.x = move_toward(velocity.x, 0.0, 8.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 8.0 * delta)
		move_and_slide()
		if _rod:
			_rod.visible = true
		if _pause <= 0.0:
			_fishing = false
			_pick_target()
		return
	var to := _fishing_spot - global_position
	to.y = 0.0
	if to.length() < 5.0:
		_pause = randf_range(12.0, 30.0)
		return
	var dir := to.normalized()
	velocity.x = move_toward(velocity.x, dir.x * _speed, 6.0 * delta)
	velocity.z = move_toward(velocity.z, dir.z * _speed, 6.0 * delta)
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), delta * 4.0)
	move_and_slide()


func _build_rod() -> void:
	_rod = MeshInstance3D.new()
	_rod.name = "FishingRod"
	var rm := BoxMesh.new()
	rm.size = Vector3(0.02, 1.5, 0.02)
	var rmat := StandardMaterial3D.new()
	rmat.albedo_color = Color(0.45, 0.32, 0.18)
	rmat.roughness = 0.8
	_rod.mesh = rm
	_rod.material_override = rmat
	_rod.position = Vector3(0.32, 0.7, 0.25)
	_rod.rotation.x = 0.9
	_rod.visible = false
	add_child(_rod)

func _interpolate_slave(delta: float) -> void:
	var k := clampf(delta * 12.0, 0.0, 1.0)
	global_position = global_position.lerp(get_meta("net_target", global_position), k)
	rotation.y = lerp_angle(rotation.y, float(get_meta("net_rot", rotation.y)), k)

func _build_gun() -> void:
	_gun = Node3D.new()
	_gun.name = "NPGGun"
	_gun.position = Vector3(0.45, 0.9, 0.15)
	_gun.visible = false
	add_child(_gun)
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = Color(0.12, 0.12, 0.14)
	body_mat.roughness = 0.6
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.05, 0.11, 0.24)
	body.mesh = bm
	body.material_override = body_mat
	_gun.add_child(body)
	var barrel := MeshInstance3D.new()
	var bm2 := BoxMesh.new()
	bm2.size = Vector3(0.026, 0.026, 0.16)
	barrel.mesh = bm2
	barrel.position = Vector3(0.0, 0.005, -0.19)
	barrel.material_override = body_mat
	_gun.add_child(barrel)
	_gun_flash = OmniLight3D.new()
	_gun_flash.light_color = Color(1.0, 0.9, 0.5)
	_gun_flash.light_energy = 0.0
	_gun_flash.omni_range = 7.0
	_gun_flash.position = Vector3(0.0, 0.01, -0.32)
	_gun.add_child(_gun_flash)

func punched() -> void:
	if _dead or _aggro or _afraid:
		return
	if world and world.has_method("_post_chat"):
		world._post_chat(display_name(), SHOUTS[randi() % SHOUTS.size()])
	if has_gun:
		_aggro = true
		_draw_gun()
		_shoot_timer = 0.4
		if is_police:
			_warn_timer = 2.0
			_warned = false
	else:
		_afraid = true

func _draw_gun() -> void:
	if _gun:
		_gun.visible = true
		_gun_out = true

func _update_robes(delta: float) -> void:
	if _flash > 0.0:
		_flash -= delta
		if _flash <= 0.0 and _robe_mat:
			_robe_mat.albedo_color = _base_color
	if _hp_fg:
		var r := clampf(float(hp) / 6.0, 0.0, 1.0)
		_hp_fg.scale.x = maxf(0.001, r)
		var m := _hp_fg.get_child(0) as MeshInstance3D
		if m and m.material_override:
			(m.material_override as StandardMaterial3D).albedo_color = (
				Color(0.9, 0.25, 0.2) if r < 0.35
				else Color(0.95, 0.75, 0.2) if r < 0.65
				else Color(0.35, 0.85, 0.35))

func _build_overhead() -> void:
	var head_y := 2.1
	_name_label = Label3D.new()
	_name_label.text = _name
	_name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_name_label.no_depth_test = true
	_name_label.modulate = Color(1, 1, 1, 0.95)
	_name_label.outline_modulate = Color(0, 0, 0, 0.8)
	_name_label.outline_size = 8
	_name_label.pixel_size = 0.005
	_name_label.font_size = 44
	_name_label.position = Vector3(0.0, head_y + 0.55, 0.0)
	add_child(_name_label)

	var root := Node3D.new()
	var bg_mat := StandardMaterial3D.new()
	bg_mat.albedo_color = Color(0.05, 0.05, 0.06, 0.7)
	bg_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	bg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	bg_mat.no_depth_test = true
	bg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	var bg := MeshInstance3D.new()
	var bgq := QuadMesh.new()
	bgq.size = Vector2(0.5, 0.07)
	bg.mesh = bgq
	bg.material_override = bg_mat
	root.add_child(bg)
	var fg_mat := StandardMaterial3D.new()
	fg_mat.albedo_color = Color(0.35, 0.85, 0.35)
	fg_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fg_mat.no_depth_test = true
	fg_mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	_hp_fg = Node3D.new()
	_hp_fg.position = Vector3(-0.25, 0.0, 0.001)
	var fg := MeshInstance3D.new()
	var fgq := QuadMesh.new()
	fgq.size = Vector2(0.5, 0.07)
	fg.mesh = fgq
	fg.position = Vector3(0.25, 0.0, 0.0)
	fg.material_override = fg_mat
	_hp_fg.add_child(fg)
	root.add_child(_hp_fg)
	root.position = Vector3(0.0, head_y + 0.15, 0.0)
	add_child(root)

func hit(dmg: int) -> void:
	if _dead:
		return
	hp -= dmg
	_flash = 0.3
	if is_police:
		_aggro = true
		_draw_gun()
		_warn_timer = 2.5
		_warned = false
	if _robe_mat:
		_robe_mat.albedo_color = Color(1.0, 0.4, 0.4)
	if hp <= 0:
		_die()

func _die() -> void:
	_dead = true
	velocity = Vector3.ZERO
	if has_gun and world and world.has_method("_spawn_gun_pickup") and not net_slave:
		world._spawn_gun_pickup(global_position)
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(self, "rotation:z", PI / 2.0, 0.4)
	tw.tween_property(self, "position:y", position.y - 0.2, 0.4)
	tw.tween_callback(queue_free)
