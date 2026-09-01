extends StaticBody3D

var world: Node
var reactor: Node
var interact_hint := "[E] Reactor Console"


func interact() -> void:
	if reactor != null and reactor.has_method("interact"):
		reactor.interact()


func get_reactor_index() -> int:
	if reactor != null:
		return int(reactor.get("plant_idx"))
	return -1
