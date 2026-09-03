extends StaticBody3D

var world: Node
var shrooms := 2

var interact_hint := "[E] Forage mushrooms (2)"


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	var cap_mat := StandardMaterial3D.new()
	cap_mat.albedo_color = Color(0.75, 0.18, 0.3)
	cap_mat.emission_enabled = true
	cap_mat.emission = Color(1.0, 0.4, 0.5) * 0.35
	cap_mat.emission_energy_multiplier = 0.8
	cap_mat.roughness = 0.5
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.88, 0.82, 0.7)
	stem_mat.roughness = 0.8
	var rng := RandomNumberGenerator.new()
	rng.seed = int(global_position.x * 37.0 + global_position.z * 11.0) + 7
	var clust := Node3D.new()
	clust.name = "Caps"
	add_child(clust)
	for i in 3:
		var offang := rng.randf() * TAU
		var offr := rng.randf_range(0.1, 0.4)
		var base := Vector3(cos(offang) * offr, 0.0, sin(offang) * offr)
		var scale := rng.randf_range(0.9, 1.3)
		var stem := MeshInstance3D.new()
		var sm := CylinderMesh.new()
		sm.top_radius = 0.05 * scale
		sm.bottom_radius = 0.07 * scale
		sm.height = 0.3 * scale
		stem.mesh = sm
		stem.material_override = stem_mat
		stem.position = base + Vector3(0.0, 0.15 * scale, 0.0)
		clust.add_child(stem)
		var cap := MeshInstance3D.new()
		var csm := SphereMesh.new()
		csm.radius = 0.12 * scale
		csm.height = 0.16 * scale
		cap.mesh = csm
		cap.material_override = cap_mat
		cap.position = base + Vector3(0.0, 0.3 * scale, 0.0)
		clust.add_child(cap)
	var col := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 0.7
	cs.height = 0.9
	col.shape = cs
	col.position = Vector3(0.0, 0.45, 0.0)
	add_child(col)


func _refresh_hint() -> void:
	interact_hint = "[E] Forage mushrooms (%d)" % shrooms


func interact() -> void:
	if world and world.has_method("_forage_mushrooms"):
		world._forage_mushrooms(self)