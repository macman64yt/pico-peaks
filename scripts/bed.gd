extends StaticBody3D

var world: Node
var interact_hint := "[E] Sleep in bed"


func interact() -> void:
	if world:
		world.sleep_in_bed()
