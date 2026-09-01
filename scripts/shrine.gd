extends StaticBody3D

var world: Node

var interact_hint := "[E] Receive the shrine's blessing"


func _ready() -> void:
	collision_layer = 2


func interact() -> void:
	if world and world.has_method("_use_shrine"):
		world._use_shrine()
