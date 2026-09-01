extends Node3D

const SPEED := 13.0
const HIT_RADIUS := 7.0
const WIND_RADIUS := 34.0
const DAMAGE := 8
const DAMAGE_INTERVAL := 0.9
const LIFETIME := 60.0

var world: Node = null
var slave := false
var net_target := Vector3.ZERO
var lifetime := LIFETIME

var _age := 0.0
var _move_to := Vector2.ZERO
var _repath := 0.0
var _dmg_t := 0.0
var _spin := 0.0
var _rip_t := 0.0
var _wind_cache_t := 0.0
var _wind_targets: Array = []
var _ripped := {}
var _roofs: Array = []
var _funnel := MeshInstance3D.new()
var _cloud := MeshInstance3D.new()
var _dust_ring := MeshInstance3D.new()
var _debris: Array[MeshInstance3D] = []
var _debris_phase: Array[float] = []
var _audio := AudioStreamPlayer3D.new()


func _ready() -> void:
	_build_visual()
	_build_audio()
	_move_to = Vector2(global_position.x, global_position.z)
	_repath = 1.0


func _process(delta: float) -> void:
	if slave:
		_age += delta
	_spin += delta * 1.6
	_funnel.rotation.y = _spin
	_cloud.rotation.y = -_spin * 0.5
	var wob := 1.0 + sin(_age * 2.3) * 0.06
	_cloud.scale = Vector3(wob, 1.0 - sin(_age * 1.7) * 0.08, wob)
	for i in _debris.size():
		_debris_phase[i] = _debris_phase[i] + delta * (2.5 + float(i) * 0.4)
		var ph := _debris_phase[i]
		var rad := 3.5 + fmod(float(i) * 0.7, 2.5)
		var hgt := 1.0 + fmod(float(i) * 1.37, 4.0)
		_debris[i].position = Vector3(cos(ph) * rad, hgt + sin(_age * 4.0 + float(i)) * 0.6, sin(ph) * rad)
		_debris[i].rotation.y += delta * 3.0
	for i in range(_roofs.size() - 1, -1, -1):
		if not is_instance_valid(_roofs[i]):
			_roofs.remove_at(i)
	_rip_t -= delta
	if _rip_t <= 0.0:
		_rip_t = 0.8
		_rip_nearby_roofs()
	if world != null and world.get("_player") != null:
		var pl: Node3D = world.get("_player")
		if is_instance_valid(pl):
			var d := global_position.distance_to(pl.global_position)
			if d < 70.0:
				var sh := maxf(0.0, 1.0 - d / 70.0)
				world.set("_tornado_shake", maxf(float(world.get("_tornado_shake")), sh))


func _physics_process(delta: float) -> void:
	if slave:
		var k := clampf(delta * 8.0, 0.0, 1.0)
		global_position = global_position.lerp(net_target, k)
		_apply_wind(delta)
		return
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	_repath -= delta
	if _repath <= 0.0:
		_repath = randf_range(3.5, 7.0)
		_pick_target()
	var to := _move_to - Vector2(global_position.x, global_position.z)
	var dist := to.length()
	var dir := to.normalized() if dist > 0.01 else Vector2.ZERO
	var step := SPEED * delta
	if dist < step:
		global_position.x = _move_to.x
		global_position.z = _move_to.y
	else:
		global_position.x += dir.x * step
		global_position.z += dir.y * step
	var gx := clampf(global_position.x, -950.0, 950.0)
	var gz := clampf(global_position.z, -950.0, 950.0)
	var gh := _ground(world, gx, gz)
	global_position.x = gx
	global_position.z = gz
	global_position.y = maxf(gh, 1.0) + 3.0 + sin(_age * 2.1) * 0.7
	_dmg_t -= delta
	if _dmg_t <= 0.0:
		_dmg_t = DAMAGE_INTERVAL
		_hit_entities()
	_apply_wind(delta)


func _ground(w: Node, wx: float, wz: float) -> float:
	if w != null and w.has_method("_ground_height"):
		return w._ground_height(wx, wz)
	return 0.0


func _pick_target() -> void:
	var cur := Vector2(global_position.x, global_position.z)
	var ang := randf() * TAU
	var r := randf_range(90.0, 260.0)
	var cand := cur + Vector2(cos(ang), sin(ang)) * r
	cand.x = clampf(cand.x, -920.0, 920.0)
	cand.y = clampf(cand.y, -920.0, 920.0)
	if _ground(world, cand.x, cand.y) < 1.5:
		_move_to = cur
	else:
		_move_to = cand


func _hit_entities() -> void:
	if world == null:
		return
	var center := global_position
	if world.get("_player") != null:
		var pl: Node3D = world.get("_player")
		if is_instance_valid(pl) and pl.global_position.distance_to(center) < HIT_RADIUS and pl.has_method("hit"):
			pl.hit(DAMAGE)
	for e in get_tree().get_nodes_in_group("zombies"):
		if e == null or not is_instance_valid(e) or bool(e.get("_dead")):
			continue
		if (e as Node3D).global_position.distance_to(center) < HIT_RADIUS and e.has_method("hit"):
			e.hit(DAMAGE)
	for e in get_tree().get_nodes_in_group("npc"):
		if e == null or not is_instance_valid(e) or bool(e.get("_dead")):
			continue
		if (e as Node3D).global_position.distance_to(center) < HIT_RADIUS and e.has_method("hit"):
			e.hit(DAMAGE)


func _rip_nearby_roofs() -> void:
	if get_tree() == null or world == null:
		return
	if _roofs.size() >= 5:
		return
	for h in get_tree().get_nodes_in_group("houses"):
		if h == null or not is_instance_valid(h):
			continue
		if _ripped.has(h.get_instance_id()):
			continue
		var hn := h as Node3D
		if hn == null:
			continue
		if hn.global_position.distance_to(global_position) > 14.0:
			continue
		if _rip_house(hn):
			_ripped[h.get_instance_id()] = true


func _rip_house(house: Node3D) -> bool:
	var pieces: Array[MeshInstance3D] = []
	for c in house.get_children():
		if c is MeshInstance3D and c.is_in_group("roofs"):
			pieces.append(c)
	if pieces.is_empty():
		return false
	var aabb := AABB()
	for p in pieces:
		var la := p.mesh.get_aabb()
		for corner in [
			la.position, la.position + Vector3(la.size.x, 0, 0),
			la.position + Vector3(0, la.size.y, 0),
			la.position + Vector3(0, 0, la.size.z),
			la.position + Vector3(la.size.x, la.size.y, 0),
			la.position + Vector3(la.size.x, 0, la.size.z),
			la.position + Vector3(0, la.size.y, la.size.z),
			la.position + la.size,
		]:
			aabb = aabb.expand(p.global_transform * corner)
	var rb := RigidBody3D.new()
	rb.name = "FlyingRoof"
	rb.collision_layer = 1
	rb.collision_mask = 1
	rb.mass = 10.0
	rb.linear_damp = 0.05
	rb.angular_damp = 0.25
	rb.position = aabb.get_center()
	for p in pieces:
		p.reparent(rb, true)
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = aabb.size + Vector3(0.06, 0.06, 0.06)
	cs.shape = bs
	cs.position = Vector3.ZERO
	rb.add_child(cs)
	if world != null and is_instance_valid(world):
		world.add_child(rb)
	elif get_tree() != null and get_tree().current_scene != null:
		get_tree().current_scene.add_child(rb)
	else:
		rb.free()
		return false
	_roofs.append(rb)
	var to_t := global_position - rb.global_position
	to_t.y = 0.0
	var dir := to_t.normalized() if to_t.length() > 0.01 else Vector3.RIGHT
	rb.apply_central_impulse(dir * 5.0 + Vector3.UP * 6.0)
	rb.apply_torque_impulse(Vector3(randf_range(-2.0, 2.0), randf_range(-2.0, 2.0), randf_range(-2.0, 2.0)) * 5.0)
	var t := get_tree().create_timer(14.0)
	t.timeout.connect(rb.queue_free)
	return true


func _apply_wind(delta: float) -> void:
	if world == null:
		return
	_wind_cache_t -= delta
	if _wind_cache_t <= 0.0:
		_wind_cache_t = 0.5
		_wind_targets.clear()
		if world.get("_player") != null and is_instance_valid(world.get("_player")):
			_wind_targets.append(world.get("_player"))
		_wind_targets.append_array(get_tree().get_nodes_in_group("zombies"))
		_wind_targets.append_array(get_tree().get_nodes_in_group("npc"))
		_wind_targets.append_array(_roofs)
	var center := global_position
	for e in _wind_targets:
		if e == null or not is_instance_valid(e):
			continue
		var to := (e as Node3D).global_position - center
		var flat := Vector2(to.x, to.z)
		var d := flat.length()
		if d > WIND_RADIUS or d < 0.01:
			continue
		var pull := 1.0 - d / WIND_RADIUS
		var inward := -flat.normalized()
		var strength := pull * pull * 24.0
		if e is CharacterBody3D:
			var b := e as CharacterBody3D
			var k := clampf(delta * 4.0, 0.0, 1.0)
			b.velocity.x = lerpf(b.velocity.x, inward.x * strength, k)
			b.velocity.z = lerpf(b.velocity.z, inward.y * strength, k)
			if d < HIT_RADIUS + 4.0:
				b.velocity.y = maxf(b.velocity.y, 7.0 + pull * 6.0)
		elif e is RigidBody3D:
			var rb := e as RigidBody3D
			rb.apply_central_force(Vector3(inward.x * strength * 2.2, pull * 9.0, inward.y * strength * 2.2) * rb.mass)
			rb.apply_torque(Vector3(pull * 28.0 * randf_range(-1.0, 1.0), pull * 20.0 * randf_range(-1.0, 1.0), pull * 28.0 * randf_range(-1.0, 1.0)) * rb.mass)


func _build_visual() -> void:
	_funnel.mesh = _make_funnel_mesh()
	var fm := StandardMaterial3D.new()
	fm.vertex_color_use_as_albedo = true
	fm.roughness = 1.0
	fm.cull_mode = BaseMaterial3D.CULL_DISABLED
	_funnel.material_override = fm
	add_child(_funnel)

	var cm := StandardMaterial3D.new()
	cm.albedo_color = Color(0.13, 0.13, 0.15)
	cm.roughness = 1.0
	var sph := SphereMesh.new()
	sph.radius = 3.0
	sph.height = 4.0
	sph.radial_segments = 18
	sph.rings = 10
	_cloud.mesh = sph
	_cloud.position.y = 95.0
	_cloud.scale = Vector3(2.2, 0.55, 2.2)
	_cloud.material_override = cm
	add_child(_cloud)

	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.42, 0.36, 0.3, 0.55)
	dm.roughness = 1.0
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var cyl := CylinderMesh.new()
	cyl.top_radius = 9.0
	cyl.bottom_radius = 9.0
	cyl.height = 0.12
	cyl.radial_segments = 24
	_dust_ring.mesh = cyl
	_dust_ring.position.y = 0.3
	_dust_ring.material_override = dm
	add_child(_dust_ring)

	for i in 6:
		var d := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.35, 0.22, 0.3)
		d.mesh = box
		var dmat := StandardMaterial3D.new()
		dmat.albedo_color = Color(0.4 + randf() * 0.2, 0.34 + randf() * 0.15, 0.28)
		dmat.roughness = 1.0
		d.material_override = dmat
		add_child(d)
		_debris.append(d)
		_debris_phase.append(randf() * TAU)


func _make_funnel_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var segments := 16
	var rings := 16
	var height := 92.0
	var base_r := 5.2
	var top_r := 0.5
	for ri in rings:
		var t := float(ri) / float(rings)
		var nt := float(ri + 1) / float(rings)
		var r0 := lerpf(base_r, top_r, t)
		var r1 := lerpf(base_r, top_r, nt)
		var y0 := t * height
		var y1 := nt * height
		var twist := t * 2.6
		var twist1 := nt * 2.6
		for si in segments:
			var a0 := float(si) / float(segments) * TAU
			var a1 := float(si + 1) / float(segments) * TAU
			var wob0 := 1.0 + 0.12 * sin(float(si) * 2.3 + t * 9.0)
			var wob1 := 1.0 + 0.12 * sin(float(si) * 2.3 + nt * 9.0)
			var p00 := Vector3(cos(a0 + twist) * r0 * wob0, y0, sin(a0 + twist) * r0 * wob0)
			var p01 := Vector3(cos(a1 + twist) * r0 * wob0, y0, sin(a1 + twist) * r0 * wob0)
			var p10 := Vector3(cos(a0 + twist1) * r1 * wob1, y1, sin(a0 + twist1) * r1 * wob1)
			var p11 := Vector3(cos(a1 + twist1) * r1 * wob1, y1, sin(a1 + twist1) * r1 * wob1)
			var col0 := Color(0.30, 0.26, 0.23).lerp(Color(0.46, 0.44, 0.43), t)
			var col1 := col0.lightened(0.06 * sin(float(si) * 3.1))
			var n := (p01 - p00).cross(p10 - p00).normalized()
			st.set_normal(n)
			st.set_color(col0)
			st.add_vertex(p00)
			st.set_normal(n)
			st.set_color(col1)
			st.add_vertex(p01)
			st.set_normal(n)
			st.set_color(col0)
			st.add_vertex(p10)
			st.set_normal(n)
			st.set_color(col1)
			st.add_vertex(p01)
			st.set_normal(n)
			st.set_color(col1)
			st.add_vertex(p11)
			st.set_normal(n)
			st.set_color(col0)
			st.add_vertex(p10)
	return st.commit()


func _build_audio() -> void:
	_audio.stream = _make_wind_wav()
	_audio.max_db = -4.0
	_audio.unit_size = 12.0
	_audio.volume_db = -14.0
	add_child(_audio)
	_audio.play()


func _make_wind_wav() -> AudioStreamWAV:
	var rate := 22050
	var frames := int(rate * 2.0)
	var data := PackedByteArray()
	data.resize(frames * 2)
	var lp := 0.0
	var lp2 := 0.0
	for i in frames:
		var s := randf() * 2.0 - 1.0
		lp = lerpf(lp, s, 0.35)
		lp2 = lerpf(lp2, lp, 0.25)
		var sample := int(clampf(lp2, -1.0, 1.0) * 32767.0)
		data[i * 2] = sample & 0xFF
		data[i * 2 + 1] = (sample >> 8) & 0xFF
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = rate
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_end = frames
	return wav
