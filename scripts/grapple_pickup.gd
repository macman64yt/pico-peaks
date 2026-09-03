extends StaticBody3D


var world: Node
var interact_hint := "[E] Pick up grappling hook"
var _glow: Node3D
var _time := 0.0


func _ready() -> void:
	collision_layer = 2
	collision_mask = 0
	var hook_mat := StandardMaterial3D.new()
	hook_mat.albedo_color = Color(0.7, 0.66, 0.6)
	hook_mat.roughness = 0.4
	var body := MeshInstance3D.new()
	var bm := CapsuleMesh.new()
	bm.radius = 0.05
	bm.height = 0.5
	body.mesh = bm
	body.material_override = hook_mat
	body.position = Vector3(0.0, 0.25, 0.0)
	add_child(body)
	_glow = MeshInstance3D.new()
	var gm := TorusMesh.new()
	gm.inner_radius = 0.15
	gm.outer_radius = 0.22
	_glow.mesh = gm
	var glow_mat := StandardMaterial3D.new()
	glow_mat.albedo_color = Color(0.2, 0.9, 0.4)
	glow_mat.emission_enabled = true
	glow_mat.emission = Color(0.2, 1.0, 0.45)
	glow_mat.emission_energy_multiplier = 1.4
	_glow.material_override = glow_mat
	_glow.position = Vector3(0.0, 0.6, 0.0)
	_glow.rotation_degrees.y = 90.0
	add_child(_glow)
	var col := CollisionShape3D.new()
	var cs := CylinderShape3D.new()
	cs.radius = 0.5
	cs.height = 1.2
	col.shape = cs
	col.position = Vector3(0.0, 0.6, 0.0)
	add_child(col)


func _process(delta: float) -> void:
	_time += delta
	if _glow:
		_glow.position.y = 0.6 + sin(_time * 3.0) * 0.1


func interact() -> void:
	if world and world.has_method("_give_player_grapple"):
		if world._give_player_grapple():
			queue_free()