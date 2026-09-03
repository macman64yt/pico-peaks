extends Node3D


var world: Node
var _mat: StandardMaterial3D
var _t := 0.0
var _fade := 0.0
var _fading := true
var _gone := false
var _target_pos := Vector3.ZERO
var _dir := 0.0


func _ready() -> void:
	_mat = StandardMaterial3D.new()
	_mat.albedo_color = Color(0.85, 0.92, 0.95, 0.0)
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.roughness = 0.9
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.backface_cull = false
	var body := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(0.5, 1.7, 0.28)
	body.mesh = bm
	body.material_override = _mat
	body.position = Vector3(0.0, 0.85, 0.0)
	add_child(body)
	var head := MeshInstance3D.new()
	var hm := SphereMesh.new()
	hm.radius = 0.16
	hm.height = 0.3
	head.mesh = hm
	head.material_override = _mat
	head.position = Vector3(0.0, 1.75, 0.0)
	add_child(head)
	var eye_mat := StandardMaterial3D.new()
	eye_mat.albedo_color = Color(1.0, 0.3, 0.25)
	eye_mat.emission_enabled = true
	eye_mat.emission = Color(1.0, 0.25, 0.2)
	eye_mat.emission_energy_multiplier = 2.0
	eye_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for ex in [-0.06, 0.06]:
		var eye := MeshInstance3D.new()
		var em := SphereMesh.new()
		em.radius = 0.03
		em.height = 0.05
		eye.mesh = em
		eye.material_override = eye_mat
		eye.position = Vector3(ex, 1.8, 0.15)
		add_child(eye)
	global_position = _target_pos


func setup(pos: Vector3, tgt: Vector3) -> void:
	_target_pos = pos
	_dir = atan2(tgt.x - pos.x, tgt.z - pos.z)


func _process(delta: float) -> void:
	_t += delta
	var pulse := 0.5 + 0.18 * sin(_t * 2.2)
	_mat.albedo_color = Color(0.85, 0.92, 0.95, _fade * pulse)
	if _fading:
		_fade = minf(1.0, _fade + delta * 0.7)
		_fade = minf(_fade, 0.85)
	rotation.y = PI + _dir
	position.y = sin(_t * 1.7) * 0.05


func despawn() -> void:
	_gone = true