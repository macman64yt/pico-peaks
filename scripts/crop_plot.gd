extends StaticBody3D

var world: Node
var crop_type := 0
var growth := 0.0
var _plants: Array[MeshInstance3D] = []
var _soil_mat: StandardMaterial3D
var _plant_mat: StandardMaterial3D

const CROP_NAMES := ["Wheat", "Pumpkin", "Corn"]
const CROP_COLORS := [
	Color(0.85, 0.78, 0.3),
	Color(0.85, 0.5, 0.1),
	Color(0.9, 0.88, 0.25)
]
const GROW_TIME := 90.0
const HEALTH_GAIN := 12.0
const STAMINA_GAIN := 15.0

var interact_hint := "[E] Harvest Wheat"


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	_soil_mat = StandardMaterial3D.new()
	_soil_mat.albedo_color = Color(0.35, 0.25, 0.15)
	_soil_mat.roughness = 1.0
	_plant_mat = StandardMaterial3D.new()
	_plant_mat.albedo_color = CROP_COLORS[crop_type]
	_plant_mat.roughness = 0.8
	_make_soil()
	_make_plants()
	growth = randf_range(0.0, 0.4)
	refresh_hint()


func _make_soil() -> void:
	var soil := MeshInstance3D.new()
	var sm := BoxMesh.new()
	sm.size = Vector3(1.2, 0.08, 1.2)
	soil.mesh = sm
	soil.material_override = _soil_mat
	soil.position = Vector3(0.0, 0.04, 0.0)
	add_child(soil)
	var col := CollisionShape3D.new()
	var cs := BoxShape3D.new()
	cs.size = Vector3(1.2, 0.4, 1.2)
	col.shape = cs
	col.position = Vector3(0.0, 0.2, 0.0)
	add_child(col)


func _make_plants() -> void:
	for i in 4:
		var plant := MeshInstance3D.new()
		var pm := BoxMesh.new()
		pm.size = Vector3(0.06, 0.2, 0.06)
		plant.mesh = pm
		plant.material_override = _plant_mat
		var ang := float(i) * PI / 2.0 + 0.4
		var rr := 0.25
		plant.position = Vector3(cos(ang) * rr, 0.18, sin(ang) * rr)
		add_child(plant)
		_plants.append(plant)


func _process(delta: float) -> void:
	if growth >= 1.0:
		_plant_mat.emission_enabled = true
		_plant_mat.emission = CROP_COLORS[crop_type] * 0.3
		_plant_mat.emission_energy_multiplier = 0.5
		return
	growth = minf(growth + delta / GROW_TIME, 1.0)
	var s := lerpf(0.3, 1.0, growth)
	for m in _plants:
		if m and is_instance_valid(m):
			m.scale = Vector3(s, s, s)
			m.position.y = 0.08 + growth * 0.18
	refresh_hint()


func reset_crop() -> void:
	for m in _plants:
		if m and is_instance_valid(m):
			m.queue_free()
	_plants.clear()
	growth = 0.0
	_make_plants()
	refresh_hint()


func refresh_hint() -> void:
	var name: String = CROP_NAMES[crop_type] as String
	if growth < 1.0:
		interact_hint = "[E] %s (%d%% grown)" % [name, int(growth * 100.0)]
	else:
		interact_hint = "[E] Harvest %s" % name


func interact() -> void:
	if world and world.has_method("_harvest_crop"):
		world._harvest_crop(self)
