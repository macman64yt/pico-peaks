extends StaticBody3D

var world: Node
var berries := 2

var interact_hint := "[E] Pick berries (2)"


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	var green_mat := StandardMaterial3D.new()
	green_mat.albedo_color = Color(0.2, 0.45, 0.18)
	green_mat.roughness = 1.0
	var dark_mat := StandardMaterial3D.new()
	dark_mat.albedo_color = Color(0.15, 0.32, 0.14)
	dark_mat.roughness = 1.0
	var berry_mat := StandardMaterial3D.new()
	berry_mat.albedo_color = Color(0.82, 0.14, 0.2)
	berry_mat.roughness = 0.4
	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.4, 0.28, 0.15)
	trunk_mat.roughness = 1.0

	var trunk := MeshInstance3D.new()
	var tm := CylinderMesh.new()
	tm.top_radius = 0.04
	tm.bottom_radius = 0.06
	tm.height = 0.35
	trunk.mesh = tm
	trunk.material_override = trunk_mat
	trunk.position = Vector3(0.0, 0.17, 0.0)
	add_child(trunk)

	var reds := Node3D.new()
	reds.name = "Reds"
	add_child(reds)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 37.0 + global_position.z * 11.0) + 1
	for i in 4:
		var ang := rng.randf() * TAU
		var rr := rng.randf_range(0.3, 0.55)
		var blob := MeshInstance3D.new()
		var bm := SphereMesh.new()
		bm.radius = 0.2
		bm.height = 0.4
		blob.mesh = bm
		blob.material_override = green_mat if i % 2 == 0 else dark_mat
		blob.position = Vector3(cos(ang) * rr, 0.5 + rng.randf_range(0.0, 0.18), sin(ang) * rr)
		add_child(blob)
	for i in 12:
		var ang := rng.randf() * TAU
		var rr := rng.randf_range(0.18, 0.52)
		var ry := 0.42 + rng.randf_range(0.0, 0.2)
		var berry := MeshInstance3D.new()
		var bsm := SphereMesh.new()
		bsm.radius = 0.03
		bsm.height = 0.06
		berry.mesh = bsm
		berry.material_override = berry_mat
		berry.position = Vector3(cos(ang) * rr, ry, sin(ang) * rr)
		reds.add_child(berry)
	var col := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 0.6
	cs.height = 1.2
	col.shape = cs
	col.position = Vector3(0.0, 0.6, 0.0)
	add_child(col)


func _refresh_hint() -> void:
	interact_hint = "[E] Pick berries (%d)" % berries


func interact() -> void:
	if world and world.has_method("_forage_berries"):
		world._forage_berries(self)
