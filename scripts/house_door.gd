extends Node3D

var _target := 0.0


func _ready() -> void:
	var area := Area3D.new()
	area.name = "Proximity"
	var shape := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.5, 2.3, 1.3)
	shape.shape = bs
	shape.position = Vector3(0.475, 1.15, 0.55)
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)


func _on_body_entered(b: Node3D) -> void:
	if b.get_meta("is_player", false) == true:
		_target = -1.5


func _on_body_exited(b: Node3D) -> void:
	if b.get_meta("is_player", false) == true:
		_target = 0.0


func _physics_process(delta: float) -> void:
	rotation.y = move_toward(rotation.y, _target, delta * 3.0)
