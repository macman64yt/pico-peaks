extends StaticBody3D

var world: Node

var interact_hint := "[E] Trade fish at the market"

const GOOD_PRICES := [1, 2, 3]
const GOOD_NAMES := ["medkit", "ammo", "a gun"]


func _ready() -> void:
	collision_layer = 2
	_refresh_hint()


func _process(_delta: float) -> void:
	_refresh_hint()


func _good() -> int:
	return clampi(int(get_meta("good", 0)), 0, 2)


func _refresh_hint() -> void:
	if world == null:
		return
	var good := _good()
	var basket: int = int(world.get("_fish_basket"))
	var price: int = GOOD_PRICES[good]
	var name: String = GOOD_NAMES[good]
	if basket < price:
		interact_hint = "[E] %d fish for %s (%d in basket)" % [price, name, basket]
	else:
		interact_hint = "[E] Trade %d fish: %s" % [price, name]


func interact() -> void:
	if world and world.has_method("_trade_fish"):
		world._trade_fish(_good())
