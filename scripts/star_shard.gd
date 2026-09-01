extends StaticBody3D

var world: Node
var _glow: Node3D
var _time := 0.0

var interact_hint := "[E] Collect star shard"


func _process(delta: float) -> void:
	_time += delta
	if _glow:
		_glow.position.y = 0.25 + sin(_time * 3.0) * 0.1
	rotation.y += delta * 0.6


func interact() -> void:
	if world and world.has_method("_give_player_shard"):
		if world._give_player_shard():
			queue_free()
