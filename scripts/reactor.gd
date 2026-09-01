extends Node3D

const NORMAL_TEMP := 300.0
const DAMAGE_TEMP := 700.0
const SCRAM_TEMP := 860.0
const MELTDOWN_TEMP := 1050.0
const RAD_RADIUS := 260.0
const BLAST_RADIUS := 170.0
const BLAST_MAX_DMG := 90.0

const REACTOR_TYPES := [
	{"name": "Experimental", "max_power": 0.45, "heat_mult": 1.6, "dmg_mult": 1.5, "coolant_mult": 0.8, "core_color": Color(1.0, 0.35, 0.15)},
	{"name": "PWR", "max_power": 0.9, "heat_mult": 1.0, "dmg_mult": 1.0, "coolant_mult": 1.0, "core_color": Color(1.0, 0.7, 0.35)},
	{"name": "Fast Breeder", "max_power": 1.3, "heat_mult": 1.35, "dmg_mult": 1.2, "coolant_mult": 1.3, "core_color": Color(0.5, 0.6, 1.0)},
]

var plant_idx := 0
var world: Node

var rods := 0.7
var coolant_on := true
var auto_scram := true
var auto_coolant := false
var auto_rods := false
var reactor_type := 1
var upgrade_t := 0.0
var fuel := 1.0
var water := 1.0
var decay_factor := 0.0
var refuel_cd := 0.0
var _fuel_alarmed := false
var temp := 320.0
var damage := 0.0
var meltdown_progress := 0.0
var exploded := false
var power01 := 0.0

var _towers: Array[Node3D] = []
var _steam_puffs: Array[MeshInstance3D] = []
var _steam_origins: Array[Vector3] = []
var _core_light: OmniLight3D
var _beacon: OmniLight3D
var _boom_light: OmniLight3D
var _steam_pool := 0.0
var _flash := 0.0
var _flicker := 0.0
var _boom_t := 0.0

var _panel: Control
var _dim: ColorRect
var _open := false
var _dragging := false
var _send_t := 0.0
var _ui := {}
var _slider: HSlider
var _coolant_btn: Button
var _auto_scram_btn: Button
var _auto_rods_btn: Button
var _auto_coolant_btn: Button
var _upgrade_btn: Button
var _refuel_btn: Button
var _water_btn: Button
var _rad_acc: Dictionary = {}


func setup(idx: int, w: Node, rng: RandomNumberGenerator) -> void:
	plant_idx = idx
	world = w
	name = "PowerPlant%d" % idx
	add_to_group("plants")
	_build_visuals(rng)
	_build_panel()
	if _core_light:
		_core_light.light_color = Color(1.0, 0.7, 0.35)
		_core_light.light_energy = 4.0


func state_row() -> Array:
	return [plant_idx, rods, 1 if coolant_on else 0, temp, power01, damage, meltdown_progress, 1 if exploded else 0, 1 if auto_scram else 0, reactor_type, upgrade_t, fuel, water, 1 if auto_coolant else 0, 1 if auto_rods else 0, decay_factor]


func apply_state(row: Array) -> void:
	rods = clampf(float(row[1]), 0.0, 1.0)
	coolant_on = bool(row[2])
	temp = float(row[3])
	power01 = float(row[4])
	damage = float(row[5])
	meltdown_progress = float(row[6])
	var ex := bool(row[7])
	if ex and not exploded:
		exploded = true
		if world != null and world.has_method("_on_reactor_meltdown"):
			world.call("_on_reactor_meltdown", plant_idx, global_position)
	exploded = ex
	if row.size() > 8:
		auto_scram = bool(row[8])
	if row.size() > 9:
		reactor_type = clampi(int(row[9]), 0, REACTOR_TYPES.size() - 1)
	if row.size() > 10:
		upgrade_t = float(row[10])
	if row.size() > 11:
		fuel = clampf(float(row[11]), 0.0, 1.0)
	if row.size() > 12:
		water = clampf(float(row[12]), 0.0, 1.0)
	if row.size() > 13:
		auto_coolant = bool(row[13])
	if row.size() > 14:
		auto_rods = bool(row[14])
	if row.size() > 15:
		decay_factor = clampf(float(row[15]), 0.0, 1.0)


func set_control(new_rods: float, new_coolant: bool, new_scram: bool) -> void:
	rods = clampf(new_rods, 0.0, 1.0)
	coolant_on = bool(new_coolant)
	auto_scram = bool(new_scram)


func _physics_process(delta: float) -> void:
	if world == null:
		return
	if bool(world.get("_client")):
		_update_visuals(delta)
		return
	if exploded:
		_tick_aftermath(delta)
		return
	if refuel_cd > 0.0:
		refuel_cd = maxf(0.0, refuel_cd - delta)
	if upgrade_t > 0.0:
		upgrade_t = maxf(0.0, upgrade_t - delta)
		rods = move_toward(rods, 0.0, delta)
		power01 = move_toward(power01, 0.0, delta * 0.5)
		temp = move_toward(temp, NORMAL_TEMP, delta * 2.0)
		if upgrade_t <= 0.0:
			reactor_type = clampi(reactor_type + 1, 0, REACTOR_TYPES.size() - 1)
			fuel = minf(1.0, fuel + 0.4)
			if world.has_method("_post_chat"):
				world.call("_post_chat", "System", "Reactor %d upgraded to %s. Capacity and cooling changed." % [plant_idx + 1, REACTOR_TYPES[reactor_type].name])
		_update_visuals(delta)
		return
	var tdef: Dictionary = REACTOR_TYPES[reactor_type]
	power01 = move_toward(power01, rods * tdef.max_power, delta * 0.25)
	if fuel > 0.02:
		fuel = maxf(0.0, fuel - power01 * 0.00035 * delta)
	if fuel <= 0.02:
		rods = move_toward(rods, 0.0, delta * 2.0)
		if fuel <= 0.0 and not _fuel_alarmed and world.has_method("_post_chat"):
			_fuel_alarmed = true
			world.call("_post_chat", "ALARM", "Reactor %d: FUEL EXHAUSTED. Refuel to continue." % (plant_idx + 1))
	var heat: float = power01 * 55.0 * float(tdef.heat_mult) + 6.0
	var cooling := 0.0
	if coolant_on:
		var cool_mult: float = float(tdef.coolant_mult) * (0.45 + 0.55 * water)
		cooling = (42.0 + (temp - NORMAL_TEMP) * 0.06) * cool_mult
		water = maxf(0.0, water - power01 * 0.00018 * delta)
	else:
		cooling = (temp - 600.0) * 0.03 * (0.5 + 0.5 * water)
	if auto_coolant and temp > NORMAL_TEMP + 60.0 and not coolant_on:
		coolant_on = true
	if auto_rods:
		var target_rods := 0.7
		if temp > NORMAL_TEMP + 120.0:
			target_rods = 0.15
		elif temp > NORMAL_TEMP + 40.0:
			target_rods = 0.4
		if temp > NORMAL_TEMP + 40.0 and not coolant_on:
			coolant_on = true
		if _grid_shortfall():
			target_rods = maxf(target_rods, 0.85)
		rods = move_toward(rods, target_rods, delta * 0.3)
	cooling *= 1.0 - decay_factor * 0.6
	if decay_factor > 0.0:
		decay_factor = maxf(0.0, decay_factor - delta / 90.0)
	temp += (heat - cooling) * delta
	if auto_scram and temp > SCRAM_TEMP and rods > 0.05:
		rods = 0.05
		if world.has_method("_post_chat"):
			world.call("_post_chat", "ALARM", "Reactor %d: core temperature critical — rods auto-inserted." % (plant_idx + 1))
	if temp > DAMAGE_TEMP:
		damage += (temp - DAMAGE_TEMP) / 180.0 * delta * tdef.dmg_mult
	if temp >= MELTDOWN_TEMP or damage >= 100.0:
		if meltdown_progress <= 0.0 and world.has_method("_post_chat"):
			world.call("_post_chat", "ALARM", "Reactor %d: MELTDOWN IN PROGRESS. Evacuate!" % (plant_idx + 1))
		meltdown_progress = minf(1.0, meltdown_progress + delta / 3.5)
		if meltdown_progress >= 1.0:
			_meltdown()
	_update_visuals(delta)


func _grid_shortfall() -> bool:
	if world == null or not world.has_method("grid_demand"):
		return false
	var g: Array = world.call("grid_demand")
	return bool(g[3]) or (g[1] < g[0] * 0.95)


func set_action(action: String, value: bool) -> void:
	match action:
		"auto_coolant":
			auto_coolant = value
		"auto_rods":
			auto_rods = value
		"refuel":
			if refuel_cd <= 0.0 and fuel < 1.0:
				fuel = 1.0
				_fuel_alarmed = false
				refuel_cd = 20.0
				if world.has_method("_post_chat"):
					world.call("_post_chat", "System", "Reactor %d: fuel rods replaced." % (plant_idx + 1))
		"water":
			if refuel_cd <= 0.0 and water < 1.0:
				water = 1.0
				refuel_cd = 15.0
				if world.has_method("_post_chat"):
					world.call("_post_chat", "System", "Reactor %d: cooling water replenished." % (plant_idx + 1))
		"upgrade":
			if upgrade_t <= 0.0 and reactor_type < REACTOR_TYPES.size() - 1 and not exploded:
				upgrade_t = 25.0
				if world.has_method("_post_chat"):
					world.call("_post_chat", "System", "Reactor %d: upgrading to %s begins. Plant offline %ds." % [plant_idx + 1, REACTOR_TYPES[reactor_type + 1].name, int(upgrade_t)])


func _meltdown() -> void:
	if exploded:
		return
	exploded = true
	meltdown_progress = 1.0
	_boom_t = 0.6
	_flash = 1.0
	if _boom_light:
		_boom_light.visible = true
		_boom_light.light_energy = 80.0
		_boom_light.omni_range = 260.0
	if world != null and world.has_method("_on_reactor_meltdown"):
		world.call("_on_reactor_meltdown", plant_idx, global_position)
	for t in _towers:
		if is_instance_valid(t):
			var dir := Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)).normalized()
			var ang := randf_range(1.1, 1.5)
			var tw := create_tween()
			tw.set_parallel(true)
			tw.tween_property(t, "rotation:x", dir.x * ang, 2.2)
			tw.tween_property(t, "rotation:z", dir.z * ang, 2.2)
			tw.tween_property(t, "position:y", t.position.y - 3.0, 2.2)


func _tick_aftermath(delta: float) -> void:
	_boom_t = maxf(0.0, _boom_t - delta)
	if _boom_light and _boom_t <= 0.0:
		_boom_light.visible = false
	if _flash > 0.0:
		_flash = maxf(0.0, _flash - delta * 3.0)
	if _core_light:
		_flicker += delta * 18.0
		_core_light.light_energy = 18.0 + sin(_flicker) * 6.0
		_core_light.light_color = Color(1.0, 0.35 + sin(_flicker * 0.7) * 0.1, 0.15)
		_core_light.omni_range = 70.0
	if _beacon:
		_beacon.visible = (sin(_flicker * 2.0) > 0.0)
	_steam_pool += delta * 5.0
	_update_steam(delta)
	_apply_radiation(delta)


func _apply_radiation(delta: float) -> void:
	if world == null or world.get_tree() == null:
		return
	var rp := global_position
	var entities: Array[Node3D] = []
	var lp: Node3D = world.get("_player")
	if lp != null:
		entities.append(lp)
	if bool(world.get("_server")):
		var net_players: Dictionary = world.get("_net_players")
		for id in net_players:
			var p: Node3D = net_players[id]
			if p != null:
				entities.append(p)
	var npcs: Array = world.get_tree().get_nodes_in_group("npc")
	var zombies: Array = world.get_tree().get_nodes_in_group("zombies")
	for n in npcs:
		entities.append(n as Node3D)
	for z in zombies:
		entities.append(z as Node3D)
	for e in entities:
		if e == null or not is_instance_valid(e):
			continue
		var d := e.global_position.distance_to(rp)
		if d >= RAD_RADIUS:
			_rad_acc.erase(e)
			continue
		var dps := 1.0 + 7.0 * (1.0 - d / RAD_RADIUS)
		if bool(e.get("hazmat")):
			dps *= 0.05
		_rad_acc[e] = float(_rad_acc.get(e, 0.0)) + dps * delta
		if float(_rad_acc[e]) >= 1.0:
			var dmg := int(_rad_acc[e])
			_rad_acc[e] = float(_rad_acc[e]) - dmg
			if e.has_method("hit"):
				e.call("hit", dmg)
			elif "health" in e:
				e.set("health", maxf(0.0, float(e.get("health")) - dmg))


func _update_visuals(delta: float) -> void:
	_flicker += delta * (3.0 + power01 * 10.0)
	if _core_light:
		var t01 := clampf((temp - NORMAL_TEMP) / 800.0, 0.0, 1.0)
		var base: Color = REACTOR_TYPES[reactor_type].core_color
		_core_light.light_energy = 3.0 + t01 * 10.0
		_core_light.light_color = base.lerp(Color(1.0, 0.3, 0.1), t01)
		_core_light.omni_range = 30.0 + t01 * 20.0
	if _beacon:
		_beacon.visible = (sin(_flicker) > 0.0) or temp > 600.0
		_beacon.light_color = Color(1.0, 0.1, 0.05) if temp > 600.0 else Color(1.0, 0.4, 0.1)
	var steam_rate := 0.4 + power01 * 2.2
	if temp > 600.0 or meltdown_progress > 0.0:
		steam_rate += 4.0
	_steam_pool += delta * steam_rate
	_update_steam(delta)


func _update_steam(delta: float) -> void:
	var avail := _steam_pool
	for i in _steam_puffs.size():
		var p := _steam_puffs[i]
		if p == null or not is_instance_valid(p):
			continue
		var m := p.material_override as StandardMaterial3D
		if p.visible:
			p.position.y += delta * 3.5
			p.position.x += sin(_flicker + float(i)) * delta * 0.6
			var a: float = m.albedo_color.a
			a = maxf(0.0, a - delta * 0.35)
			m.albedo_color = Color(1.0, 1.0, 1.0, a)
			if a <= 0.02:
				p.visible = false
				p.position = _steam_origins[i]
		else:
			if avail >= 1.0:
				avail -= 1.0
				p.visible = true
				p.position = _steam_origins[i]
				m.albedo_color = Color(1.0, 1.0, 1.0, 0.55)
	if _steam_pool > 6.0:
		_steam_pool = 6.0


func _build_steam(parent: Node3D, origin: Vector3, count: int) -> void:
	for i in count:
		var sm := SphereMesh.new()
		sm.radius = 1.6
		sm.height = 3.0
		sm.radial_segments = 8
		sm.rings = 4
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = Color(1.0, 1.0, 1.0, 0.0)
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		var mi := MeshInstance3D.new()
		mi.mesh = sm
		mi.material_override = mat
		mi.position = origin
		mi.scale = Vector3(1.0, 1.4, 1.0)
		mi.visible = false
		parent.add_child(mi)
		_steam_puffs.append(mi)
		_steam_origins.append(origin)


func _add_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	var mi := MeshInstance3D.new()
	mi.mesh = bm
	mi.position = pos
	if rot != Vector3.ZERO:
		mi.rotation_degrees = rot
	if mat != null:
		mi.material_override = mat
	parent.add_child(mi)
	return mi


func _add_cylinder(parent: Node3D, r_b: float, r_t: float, height: float, sides: int, col: Color, pos: Vector3, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = r_t
	cm.bottom_radius = r_b
	cm.height = height
	cm.radial_segments = sides
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.8
	mi.mesh = cm
	mi.material_override = mat
	mi.position = pos
	if rot != Vector3.ZERO:
		mi.rotation_degrees = rot
	parent.add_child(mi)
	return mi


func _build_visuals(rng: RandomNumberGenerator) -> void:
	var concrete := StandardMaterial3D.new()
	concrete.albedo_color = Color(0.78, 0.78, 0.76)
	concrete.roughness = 0.95
	var concrete_dark := StandardMaterial3D.new()
	concrete_dark.albedo_color = Color(0.60, 0.60, 0.59)
	concrete_dark.roughness = 0.95
	var hazard := StandardMaterial3D.new()
	hazard.albedo_color = Color(0.55, 0.55, 0.5)
	hazard.roughness = 0.9

	_add_box(self, Vector3(108.0, 0.4, 106.0), Vector3(1.0, -0.15, 0.0), concrete_dark)

	_add_cylinder(self, 16.0, 16.0, 14.0, 20, Color(0.80, 0.80, 0.78), Vector3(0.0, 7.0, 0.0))
	_core_light = OmniLight3D.new()
	_core_light.position = Vector3(0.0, 7.0, 0.0)
	_core_light.omni_range = 40.0
	_core_light.light_energy = 3.0
	_core_light.shadow_enabled = false
	add_child(_core_light)
	var dome_mi := MeshInstance3D.new()
	var dome_mesh := SphereMesh.new()
	dome_mesh.radius = 16.0
	dome_mesh.height = 16.0
	dome_mesh.is_hemisphere = true
	dome_mesh.radial_segments = 24
	dome_mesh.rings = 8
	dome_mi.mesh = dome_mesh
	dome_mi.position = Vector3(0.0, 14.0, 0.0)
	dome_mi.material_override = concrete
	add_child(dome_mi)
	var band := _add_box(self, Vector3(33.0, 0.6, 33.0), Vector3(0.0, 14.3, 0.0), hazard)
	band.rotation_degrees = Vector3(0.0, 45.0, 0.0)

	for i in 3:
		var ang := TAU / 3.0 * i + rng.randf() * 0.5
		var dist := rng.randf_range(30.0, 40.0)
		var tower := _make_cooling_tower(rng)
		tower.position = Vector3(cos(ang) * dist, 0.0, sin(ang) * dist)
		add_child(tower)
		_towers.append(tower)

	_add_box(self, Vector3(46.0, 15.0, 22.0), Vector3(30.0, 7.5, 0.0), concrete_dark)
	_add_box(self, Vector3(48.0, 1.2, 24.0), Vector3(30.0, 15.6, 0.0), concrete)

	var cb := Node3D.new()
	cb.name = "ControlBuilding"
	add_child(cb)
	var glass := StandardMaterial3D.new()
	glass.albedo_color = Color(0.35, 0.6, 0.85)
	glass.emission_enabled = true
	glass.emission = Color(0.2, 0.45, 0.7) * 0.6
	glass.roughness = 0.1
	var cb_wall := StandardMaterial3D.new()
	cb_wall.albedo_color = Color(0.72, 0.72, 0.70)
	cb_wall.roughness = 0.9
	_add_box(cb, Vector3(20.0, 7.0, 0.3), Vector3(-22.0, 3.5, -5.85), cb_wall)
	_add_box(cb, Vector3(0.3, 7.0, 12.0), Vector3(-12.15, 3.5, 0.0), cb_wall)
	_add_box(cb, Vector3(0.3, 7.0, 12.0), Vector3(-31.85, 3.5, 0.0), cb_wall)
	_add_box(cb, Vector3(9.0, 7.0, 0.3), Vector3(-29.0, 3.5, 5.85), cb_wall)
	_add_box(cb, Vector3(9.0, 7.0, 0.3), Vector3(-15.0, 3.5, 5.85), cb_wall)
	_add_box(cb, Vector3(5.4, 0.8, 0.4), Vector3(-22.0, 6.6, 5.85), cb_wall)
	_add_box(cb, Vector3(22.0, 0.8, 14.0), Vector3(-22.0, 7.4, 0.0), concrete)
	for gx in [-1, 1]:
		for gy in [-1, 0, 1]:
			_add_box(cb, Vector3(3.4, 1.6, 0.12), Vector3(-22.0 + gx * 7.0, 3.2, gy * 3.4 - 5.85 * 0.5), glass)
	for gz in [1, -1]:
		var win := _add_box(cb, Vector3(0.12, 1.6, 3.4), Vector3(-31.85, 3.2, gz * 3.4), glass)
	var sign := Label3D.new()
	sign.text = "CONTROL ROOM"
	sign.position = Vector3(-22.0, 5.5, 5.0)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.pixel_size = 0.006
	sign.outline_size = 6
	sign.modulate = Color(0.9, 0.95, 1.0)
	cb.add_child(sign)

	_beacon = OmniLight3D.new()
	_beacon.position = Vector3(0.0, 30.0, 0.0)
	_beacon.omni_range = 45.0
	_beacon.light_energy = 7.0
	_beacon.light_color = Color(1.0, 0.4, 0.1)
	_beacon.shadow_enabled = false
	add_child(_beacon)
	_beacon.visible = false

	var console := _make_console(cb)
	cb.add_child(console)

	_boom_light = OmniLight3D.new()
	_boom_light.name = "BoomLight"
	_boom_light.position = Vector3(0.0, 10.0, 0.0)
	_boom_light.omni_range = 260.0
	_boom_light.light_energy = 80.0
	_boom_light.light_color = Color(1.0, 0.95, 0.8)
	_boom_light.visible = false
	add_child(_boom_light)

	for i in _towers.size():
		var top := _towers[i].position + Vector3(0.0, 40.0, 0.0)
		_build_steam(self, top, 3)

	var fence := _make_fence(rng)
	add_child(fence)

	var body := StaticBody3D.new()
	body.name = "PlantCollision"
	_add_collision(body, _box(108.0, 0.6, 106.0), Vector3(1.0, -0.2, 0.0), Vector3(1.0, -0.2, 0.0))
	var cshape := CylinderShape3D.new()
	cshape.radius = 16.5
	cshape.height = 14.0
	_add_collision(body, cshape, Vector3(16.5, 14.0, 0.0), Vector3(0.0, 7.0, 0.0))
	_add_collision(body, _box(46.0, 15.0, 22.0), Vector3(30.0, 7.5, 0.0), Vector3(30.0, 7.5, 0.0))
	_add_collision(body, _box(20.0, 7.0, 0.3), Vector3(-22.0, 3.5, -5.85), Vector3(-22.0, 3.5, -5.85))
	_add_collision(body, _box(0.3, 7.0, 12.0), Vector3(-12.15, 3.5, 0.0), Vector3(-12.15, 3.5, 0.0))
	_add_collision(body, _box(0.3, 7.0, 12.0), Vector3(-31.85, 3.5, 0.0), Vector3(-31.85, 3.5, 0.0))
	_add_collision(body, _box(9.0, 7.0, 0.3), Vector3(-29.0, 3.5, 5.85), Vector3(-29.0, 3.5, 5.85))
	_add_collision(body, _box(9.0, 7.0, 0.3), Vector3(-15.0, 3.5, 5.85), Vector3(-15.0, 3.5, 5.85))
	_add_collision(body, _box(22.0, 0.8, 14.0), Vector3(-22.0, 7.4, 0.0), Vector3(-22.0, 7.4, 0.0))
	add_child(body)


func _box(w: float, h: float, d: float) -> BoxShape3D:
	var bs := BoxShape3D.new()
	bs.size = Vector3(w, h, d)
	return bs


func _add_collision(parent: Node, shape: Shape3D, size: Vector3, pos: Vector3) -> void:
	var col := CollisionShape3D.new()
	col.shape = shape
	col.position = pos
	parent.add_child(col)


func _make_cooling_tower(rng: RandomNumberGenerator) -> Node3D:
	var node := Node3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var h := 44.0
	var rings := 14
	var sides := 16
	var col := Color(0.82, 0.82, 0.80)
	for iz in rings:
		var t := float(iz) / (rings - 1)
		var y := t * h
		var r := lerpf(10.5, 7.0, t) + 4.5 * sin(PI * t)
		var next_t := float(iz + 1) / (rings - 1)
		var next_r := lerpf(10.5, 7.0, next_t) + 4.5 * sin(PI * next_t)
		var dy := h / (rings - 1)
		for iside in sides:
			var a0 := float(iside) / sides * TAU
			var a1 := float(iside + 1) / sides * TAU
			var p0 := Vector3(cos(a0) * r, y, sin(a0) * r)
			var p1 := Vector3(cos(a1) * r, y, sin(a1) * r)
			var p2 := Vector3(cos(a1) * next_r, y + dy, sin(a1) * next_r)
			var p3 := Vector3(cos(a0) * next_r, y + dy, sin(a0) * next_r)
			var n0 := Vector3(cos(a0), 0.1, sin(a0)).normalized()
			var n1 := Vector3(cos(a1), 0.1, sin(a1)).normalized()
			st.set_normal(n0)
			st.set_color(col)
			st.add_vertex(p0)
			st.set_normal(n1)
			st.set_color(col)
			st.add_vertex(p1)
			st.set_normal(n1)
			st.set_color(col)
			st.add_vertex(p2)
			st.set_normal(n0)
			st.set_color(col)
			st.add_vertex(p0)
			st.set_normal(n1)
			st.set_color(col)
			st.add_vertex(p2)
			st.set_normal(n0)
			st.set_color(col)
			st.add_vertex(p3)
	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _tower_mat()
	mi.position = Vector3.ZERO
	node.add_child(mi)
	_add_collision(node, CylinderShape3D.new(), Vector3(11.0, h, 0.0), Vector3(0.0, h * 0.5, 0.0))
	return node


func _tower_mat() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.82, 0.82, 0.80)
	mat.roughness = 0.9
	return mat


func _make_fence(rng: RandomNumberGenerator) -> Node3D:
	var node := Node3D.new()
	var rail := StandardMaterial3D.new()
	rail.albedo_color = Color(0.7, 0.72, 0.75)
	rail.roughness = 0.7
	var posts := 16
	for i in posts:
		var a := TAU / posts * i
		var pos := Vector3(cos(a) * 52.0, 0.0, sin(a) * 52.0)
		_add_cylinder(node, 0.14, 0.14, 3.2, 6, Color(0.55, 0.55, 0.58), pos + Vector3(0.0, 1.6, 0.0))
		_add_cylinder(node, 0.18, 0.18, 0.5, 6, Color(0.8, 0.2, 0.1), pos + Vector3(0.0, 3.4, 0.0))
		if i % 2 == 0:
			var seg_a := pos
			var seg_b := Vector3(cos(TAU / posts * (i + 1)) * 52.0, 0.0, sin(TAU / posts * (i + 1)) * 52.0)
			var mid := (seg_a + seg_b) * 0.5
			var len := seg_a.distance_to(seg_b)
			var wire := _add_box(node, Vector3(len, 0.06, 0.06), mid + Vector3(0.0, 2.6, 0.0), rail)
			wire.rotation_degrees = Vector3(0.0, rad_to_deg(atan2(seg_b.x - seg_a.x, seg_b.z - seg_a.z)), 0.0)
	return node


func _make_console(cb: Node3D) -> Node3D:
	var node := Node3D.new()
	node.name = "ReactorConsole"
	var desk_mat := StandardMaterial3D.new()
	desk_mat.albedo_color = Color(0.25, 0.27, 0.31)
	desk_mat.roughness = 0.6
	var screen_mat := StandardMaterial3D.new()
	screen_mat.albedo_color = Color(0.05, 0.12, 0.1)
	screen_mat.emission_enabled = true
	screen_mat.emission = Color(0.1, 0.5, 0.4) * 0.5
	screen_mat.roughness = 0.3
	var console_node := Node3D.new()
	console_node.position = Vector3(-22.0, 0.0, 3.2)
	node.add_child(console_node)
	_add_box(console_node, Vector3(3.2, 1.2, 1.0), Vector3(0.0, 1.1, 0.5), desk_mat)
	var screen := _add_box(console_node, Vector3(2.6, 1.0, 0.1), Vector3(0.0, 1.7, -0.05), screen_mat)
	screen.rotation_degrees = Vector3(30.0, 0.0, 0.0)
	for bx in [-0.8, 0.8]:
		_add_cylinder(console_node, 0.12, 0.12, 0.14, 8, Color(0.8, 0.3, 0.2), Vector3(bx, 1.15, 0.9))
	_add_cylinder(console_node, 0.1, 0.1, 0.18, 8, Color(0.2, 0.6, 0.3), Vector3(0.0, 1.15, 1.5))

	var col := preload("res://scripts/reactor_console.gd").new()
	col.name = "ConsoleInteract"
	col.world = world
	col.reactor = self
	var bs := BoxShape3D.new()
	bs.size = Vector3(3.4, 1.6, 1.6)
	var shape := CollisionShape3D.new()
	shape.shape = bs
	shape.position = Vector3(-22.0, 1.3, 3.2)
	col.add_child(shape)
	col.collision_layer = 2
	node.add_child(col)
	return node


func _build_panel() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 25
	add_child(layer)

	_dim = ColorRect.new()
	_dim.color = Color(0.0, 0.0, 0.0, 0.4)
	_dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(_dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.05, 0.09, 0.07, 0.97)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(24)
	style.set_border_width_all(2)
	style.border_color = Color(0.1, 0.5, 0.4)
	panel.add_theme_stylebox_override("panel", style)
	layer.add_child(panel)

	var root := VBoxContainer.new()
	root.add_theme_constant_override("separation", 10)
	panel.add_child(root)

	var title := Label.new()
	title.text = "REACTOR %d  —  CONTROL ROOM" % (plant_idx + 1)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color(0.7, 1.0, 0.9))
	root.add_child(title)

	var sub := Label.new()
	sub.text = "Control rods absorb neutrons. Shut off pumps + pull rods = meltdown."
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 13)
	sub.add_theme_color_override("font_color", Color(0.5, 0.65, 0.6))
	root.add_child(sub)
	root.add_child(HSeparator.new())

	_ui["temp"] = _make_row(root, "CORE TEMP")
	_ui["power"] = _make_row(root, "POWER OUTPUT")
	_ui["rods"] = _make_row(root, "CONTROL RODS")
	_ui["coolant"] = _make_row(root, "COOLANT PUMPS")
	_ui["damage"] = _make_row(root, "CORE DAMAGE")
	_ui["status"] = _make_row(root, "STATUS")
	_ui["type"] = _make_row(root, "REACTOR TYPE")
	_ui["fuel"] = _make_row(root, "FUEL")
	_ui["water"] = _make_row(root, "COOLING WATER")
	_ui["grid"] = _make_row(root, "GRID")

	root.add_child(HSeparator.new())
	var rods_label := Label.new()
	rods_label.text = "CONTROL RODS"
	rods_label.add_theme_font_size_override("font_size", 14)
	root.add_child(rods_label)
	_slider = HSlider.new()
	_slider.min_value = 0.0
	_slider.max_value = 100.0
	_slider.step = 1.0
	_slider.value = rods * 100.0
	_slider.custom_minimum_size = Vector2(320.0, 0.0)
	_slider.drag_started.connect(func() -> void: _dragging = true)
	_slider.drag_ended.connect(func(_changed: bool) -> void:
		_dragging = false
		_send_control())
	_slider.value_changed.connect(func(_v: float) -> void:
		rods = clampf(_v / 100.0, 0.0, 1.0)
		if _dragging:
			_send_control_throttled())
	root.add_child(_slider)
	var rods_note := Label.new()
	rods_note.text = "0%% = fully inserted (shutdown)    100%% = fully withdrawn (full power)"
	rods_note.add_theme_font_size_override("font_size", 12)
	rods_note.add_theme_color_override("font_color", Color(0.55, 0.6, 0.6))
	root.add_child(rods_note)

	var coolant_row := HBoxContainer.new()
	coolant_row.add_theme_constant_override("separation", 12)
	root.add_child(coolant_row)
	_coolant_btn = Button.new()
	_coolant_btn.custom_minimum_size = Vector2(0.0, 40.0)
	_coolant_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_coolant_btn.pressed.connect(func() -> void:
		coolant_on = not coolant_on
		_send_control())
	coolant_row.add_child(_coolant_btn)
	var scram_btn := Button.new()
	scram_btn.text = "SCRAM (insert rods + pumps on)"
	scram_btn.custom_minimum_size = Vector2(0.0, 40.0)
	scram_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scram_btn.pressed.connect(func() -> void:
		rods = 0.03
		coolant_on = true
		_slider.value = 3.0
		_send_control())
	coolant_row.add_child(scram_btn)
	_auto_scram_btn = Button.new()
	_auto_scram_btn.custom_minimum_size = Vector2(0.0, 40.0)
	_auto_scram_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_auto_scram_btn.pressed.connect(func() -> void:
		auto_scram = not auto_scram
		_send_control())
	coolant_row.add_child(_auto_scram_btn)

	var auto_row := HBoxContainer.new()
	auto_row.add_theme_constant_override("separation", 12)
	root.add_child(auto_row)
	_auto_rods_btn = Button.new()
	_auto_rods_btn.custom_minimum_size = Vector2(0.0, 40.0)
	_auto_rods_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_auto_rods_btn.pressed.connect(func() -> void:
		auto_rods = not auto_rods
		_send_action("auto_rods", auto_rods))
	auto_row.add_child(_auto_rods_btn)
	_auto_coolant_btn = Button.new()
	_auto_coolant_btn.custom_minimum_size = Vector2(0.0, 40.0)
	_auto_coolant_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_auto_coolant_btn.pressed.connect(func() -> void:
		auto_coolant = not auto_coolant
		_send_action("auto_coolant", auto_coolant))
	auto_row.add_child(_auto_coolant_btn)

	var res_row := HBoxContainer.new()
	res_row.add_theme_constant_override("separation", 12)
	root.add_child(res_row)
	_refuel_btn = Button.new()
	_refuel_btn.custom_minimum_size = Vector2(0.0, 40.0)
	_refuel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_refuel_btn.pressed.connect(func() -> void: _send_action("refuel", true))
	res_row.add_child(_refuel_btn)
	_water_btn = Button.new()
	_water_btn.custom_minimum_size = Vector2(0.0, 40.0)
	_water_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_water_btn.pressed.connect(func() -> void: _send_action("water", true))
	res_row.add_child(_water_btn)

	var up_row := HBoxContainer.new()
	up_row.add_theme_constant_override("separation", 12)
	root.add_child(up_row)
	_upgrade_btn = Button.new()
	_upgrade_btn.custom_minimum_size = Vector2(0.0, 40.0)
	_upgrade_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_upgrade_btn.pressed.connect(func() -> void: _send_action("upgrade", true))
	up_row.add_child(_upgrade_btn)

	var close_btn := Button.new()
	close_btn.text = "Leave Console"
	close_btn.custom_minimum_size = Vector2(0.0, 40.0)
	close_btn.pressed.connect(func() -> void: _close_panel())
	root.add_child(close_btn)

	_panel = panel
	panel.visible = false
	_dim.visible = false


func _make_row(parent: Node, label: String) -> Label:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	parent.add_child(row)
	var name := Label.new()
	name.text = label
	name.custom_minimum_size = Vector2(190.0, 0.0)
	name.add_theme_font_size_override("font_size", 15)
	name.add_theme_color_override("font_color", Color(0.6, 0.75, 0.7))
	row.add_child(name)
	var value := Label.new()
	value.text = "---"
	value.add_theme_font_size_override("font_size", 16)
	value.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	row.add_child(value)
	return value


func interact() -> void:
	if world == null:
		return
	if exploded:
		if world.has_method("_post_chat"):
			world.call("_post_chat", "System", "Reactor %d is destroyed. The console is dead." % (plant_idx + 1))
		return
	if _open:
		return
	_open = true
	if world.has_method("set_reactor_panel_open"):
		world.call("set_reactor_panel_open", true)
	var p: Node3D = world.get("_player")
	if p != null:
		p.set("_freeze", true)
	_panel.visible = true
	_dim.visible = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if world.has_method("_post_chat"):
		world.call("_post_chat", "System", "Reactor %d console online. Rods, pumps, SCRAM." % (plant_idx + 1))


func _close_panel() -> void:
	if not _open:
		return
	_open = false
	if world.has_method("set_reactor_panel_open"):
		world.call("set_reactor_panel_open", false)
	var p: Node3D = world.get("_player")
	if p != null:
		p.set("_freeze", false)
	_panel.visible = false
	_dim.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _unhandled_input(event: InputEvent) -> void:
	if not _open:
		return
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_close_panel()
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if _send_t > 0.0:
		_send_t = maxf(0.0, _send_t - delta)
	if _open:
		_refresh_ui()
		if _slider and not _dragging:
			_slider.set_value_no_signal(rods * 100.0)


func _refresh_ui() -> void:
	if _ui.is_empty():
		return
	var dmg_pct := int(clampf(damage, 0.0, 100.0))
	var melt := meltdown_progress > 0.0
	var temp_col := Color(0.4, 0.9, 1.0)
	var temp_text := "%d C" % int(temp)
	if temp > DAMAGE_TEMP:
		temp_col = Color(1.0, 0.5, 0.2)
		temp_text += "  DANGER"
	if temp > MELTDOWN_TEMP or melt:
		temp_col = Color(1.0, 0.15, 0.1)
		temp_text = "!!! MELTDOWN !!!"
	_ui["temp"].text = temp_text
	_ui["temp"].add_theme_color_override("font_color", temp_col)
	_ui["power"].text = "%d MW" % int(power01 * 1000.0)
	_ui["rods"].text = "%d%%" % int(rods * 100.0)
	_ui["coolant"].text = "ON  (removing heat)" if coolant_on else "OFF  (core heating)"
	_ui["coolant"].add_theme_color_override("font_color", Color(0.5, 1.0, 0.6) if coolant_on else Color(1.0, 0.4, 0.3))
	_ui["damage"].text = "%d%%" % dmg_pct
	_ui["damage"].add_theme_color_override("font_color", Color(1.0, 0.3, 0.2) if dmg_pct > 60 else Color(0.95, 0.95, 1.0))
	var status := "OPERATIONAL"
	var status_col := Color(0.5, 1.0, 0.6)
	if melt:
		status = "MELTDOWN IN PROGRESS"
		status_col = Color(1.0, 0.1, 0.05)
	elif temp > SCRAM_TEMP:
		status = "CRITICAL — auto-scram"
		status_col = Color(1.0, 0.5, 0.1)
	elif temp > DAMAGE_TEMP:
		status = "OVERHEATING"
		status_col = Color(1.0, 0.7, 0.2)
	elif not coolant_on:
		status = "PUMPS OFF — temp rising"
		status_col = Color(1.0, 0.8, 0.3)
	_ui["status"].text = status
	_ui["status"].add_theme_color_override("font_color", status_col)
	var tdef: Dictionary = REACTOR_TYPES[reactor_type]
	_ui["type"].text = tdef.name
	_ui["type"].add_theme_color_override("font_color", Color(0.7, 0.8, 1.0))
	_ui["fuel"].text = "%d%%" % int(fuel * 100.0)
	_ui["fuel"].add_theme_color_override("font_color", Color(1.0, 0.8, 0.3) if fuel < 0.2 else Color(0.95, 0.98, 1.0))
	_ui["water"].text = "%d%%" % int(water * 100.0)
	_ui["water"].add_theme_color_override("font_color", Color(0.5, 0.8, 1.0) if water > 0.2 else Color(1.0, 0.4, 0.3))
	if world and world.has_method("grid_demand"):
		var g: Array = world.call("grid_demand")
		_ui["grid"].text = "%d / %d MW  %s" % [int(g[0]), int(g[1]), str(g[2])]
		_ui["grid"].add_theme_color_override("font_color", Color(1.0, 0.3, 0.2) if bool(g[3]) else Color(0.6, 1.0, 0.7))
	else:
		_ui["grid"].text = "offline"
	if _coolant_btn:
		_coolant_btn.text = "Coolant Pumps: %s" % ("ON" if coolant_on else "OFF")
	if _auto_scram_btn:
		_auto_scram_btn.text = "AUTO SCRAM: %s" % ("ON" if auto_scram else "OFF (override)")
	if _auto_rods_btn:
		_auto_rods_btn.text = "AUTO RODS: %s" % ("ON" if auto_rods else "OFF")
	if _auto_coolant_btn:
		_auto_coolant_btn.text = "AUTO COOLANT: %s" % ("ON" if auto_coolant else "OFF")
	if _refuel_btn:
		_refuel_btn.text = "Refuel" if fuel >= 1.0 else "Refuel (cooldown %ds)" % int(refuel_cd)
		_refuel_btn.disabled = fuel >= 1.0 or refuel_cd > 0.0
	if _water_btn:
		_water_btn.text = "Replenish Water" if water >= 1.0 else "Water (cooldown %ds)" % int(refuel_cd)
		_water_btn.disabled = water >= 1.0 or refuel_cd > 0.0
	if _upgrade_btn:
		if upgrade_t > 0.0:
			_upgrade_btn.text = "Upgrading... %ds remaining" % int(upgrade_t)
			_upgrade_btn.disabled = true
		elif reactor_type >= REACTOR_TYPES.size() - 1:
			_upgrade_btn.text = "MAX UPGRADE (%s)" % tdef.name
			_upgrade_btn.disabled = true
		else:
			_upgrade_btn.text = "UPGRADE → %s (25s offline)" % REACTOR_TYPES[reactor_type + 1].name
			_upgrade_btn.disabled = false


func _send_control() -> void:
	if world == null:
		return
	if bool(world.get("_client")):
		if world.has_method("_sv_reactor_control"):
			world._sv_reactor_control.rpc_id(1, plant_idx, rods, coolant_on, auto_scram)
	elif world.has_method("_sv_reactor_control"):
		world._sv_reactor_control(plant_idx, rods, coolant_on, auto_scram)


func _send_control_throttled() -> void:
	if _send_t > 0.0:
		return
	_send_t = 0.12
	_send_control()


func _send_action(action: String, value: bool) -> void:
	if world == null:
		return
	if bool(world.get("_client")):
		if world.has_method("_sv_reactor_action"):
			world._sv_reactor_action.rpc_id(1, plant_idx, action, value)
	elif world.has_method("_sv_reactor_action"):
		world._sv_reactor_action(plant_idx, action, value)
