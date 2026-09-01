extends StaticBody3D

var world: Node
var _glow: Node3D
var _time := 0.0

var interact_hint := "[E] Pick up gun"


func _process(delta: float) -> void:
	_time += delta
	if _glow:
		_glow.position.y = 0.25 + sin(_time * 3.0) * 0.1


func interact() -> void:
	if world:
		world._give_player_gun()
		queue_free()
