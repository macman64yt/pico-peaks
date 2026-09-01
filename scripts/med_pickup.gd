extends StaticBody3D

var world: Node
var _glow: Node3D
var _time := 0.0

var interact_hint := "[E] Pick up medkit"


func _process(delta: float) -> void:
	_time += delta
	if _glow:
		_glow.position.y = 0.2 + sin(_time * 3.0) * 0.075


func interact() -> void:
	if world and world.has_method("_give_player_meds"):
		if world._give_player_meds():
			queue_free()
