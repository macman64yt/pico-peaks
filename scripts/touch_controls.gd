extends Control

var world: Object

const BASE_RADIUS := 60.0
const LOOK_MULT := 0.9

var ui_scale := 1.0
var _last_ui_scale := 1.0
var _last_vp := Vector2.ZERO

var _move_vec := Vector2.ZERO
var _joy_active := false
var _joy_base := Vector2.ZERO
var _joy_knob := Vector2.ZERO
var _moves := {}
var _looks := {}
var _held := {}

var _vp_size := Vector2(1280, 720)
var _move_center := Vector2(160, 560)
var _fire_pos := Vector2(1180, 620)
var _jump_pos := Vector2(1030, 700)
var _sprint_pos := Vector2(900, 700)
var _interact_pos := Vector2(1145, 470)
var _light_pos := Vector2(900, 810)
var _reload_pos := Vector2(1200, 440)
var _phone_pos := Vector2(90, 90)
var _view_pos := Vector2(1280 - 60, 150)
var _pause_pos := Vector2(1280 - 60, 60)
var _chat_pos := Vector2(90, 200)

const BTN_R := {
	"shoot": 70.0,
	"jump": 56.0,
	"sprint": 52.0,
	"interact": 48.0,
	"light_toggle": 46.0,
	"reload": 48.0,
	"phone": 44.0,
	"view_toggle": 40.0,
	"chat": 40.0,
	"pause": 40.0,
}


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_process(true)
	set_process_input(true)


func _process(_delta: float) -> void:
	var paused := get_tree().paused
	if visible == paused:
		visible = not paused
		if paused:
			_clear_input()
	var vp := get_viewport().get_visible_rect().size
	if vp.x > 0:
		_vp_size = vp
	if ui_scale != _last_ui_scale or vp != _last_vp:
		_last_ui_scale = ui_scale
		_last_vp = vp
		_refresh_layout()
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var vp := get_viewport().get_visible_rect().size
	if vp.x > 0:
		_vp_size = vp
	_refresh_layout()

	if event is InputEventScreenTouch:
		var i: int = event.index
		var p: Vector2 = event.position
		if event.pressed:
			var act := _button_at(p)
			if act != "":
				if act == "pause":
					if world and world.has_method("_toggle_pause"):
						world._toggle_pause()
				elif act == "chat":
					if world and world.has_method("_toggle_chat"):
						world._toggle_chat()
				else:
					_held[i] = act
					if world and world.has_method("_touch_action"):
						world._touch_action(act)
			elif _in_move_zone(p):
				_moves[i] = p
				_joy_active = true
				_joy_base = p
				_joy_knob = p
			else:
				_looks[i] = p
		else:
			if _held.has(i):
				var act: String = _held[i]
				Input.action_release(act)
				_held.erase(i)
			elif _moves.has(i):
				_moves.erase(i)
				_joy_active = not _moves.is_empty()
				_move_vec = Vector2.ZERO
				_send_move()
			_looks.erase(i)
	elif event is InputEventScreenDrag:
		var i: int = event.index
		var p: Vector2 = event.position
		if _moves.has(i):
			_joy_base = _moves[i]
			_joy_knob = p
			var delta: Vector2 = p - _joy_base
			var rad := BASE_RADIUS * ui_scale
			if delta.length() > rad:
				delta = delta.normalized() * rad
				_joy_knob = _joy_base + delta
			_move_vec = delta / rad
			_send_move()
		elif _looks.has(i):
			var lastp: Vector2 = _looks[i]
			var delta: Vector2 = p - lastp
			_looks[i] = p
			if world and world.has_method("_touch_look"):
				world._touch_look(delta.x * LOOK_MULT, delta.y * LOOK_MULT)


func _button_at(p: Vector2) -> String:
	var pos := {
		"shoot": _fire_pos,
		"jump": _jump_pos,
		"sprint": _sprint_pos,
		"interact": _interact_pos,
		"light_toggle": _light_pos,
		"reload": _reload_pos,
		"phone": _phone_pos,
		"view_toggle": _view_pos,
		"chat": _chat_pos,
		"pause": _pause_pos,
	}
	for act in pos:
		if p.distance_to(pos[act]) <= BTN_R[act] * ui_scale:
			return act
	return ""


func _in_move_zone(p: Vector2) -> bool:
	return p.x < _vp_size.x * 0.5 - 40.0 * ui_scale


func _refresh_layout() -> void:
	var w := _vp_size.x
	var h := _vp_size.y
	var unit := minf(w / 720.0, h / 720.0) * ui_scale
	var margin := 90.0 * unit
	_move_center = Vector2(margin, h - margin)
	var br := 105.0 * unit
	_fire_pos = Vector2(w - br, h - br)
	_jump_pos = Vector2(w - br - 125 * unit, h - 40 * unit)
	_sprint_pos = Vector2(w - br - 225 * unit, h - 40 * unit)
	_interact_pos = Vector2(w - br, h - br - 155 * unit)
	_light_pos = Vector2(w - br - 225 * unit, h - br - 125 * unit)
	_reload_pos = Vector2(w - 60 * unit, h - br - 260 * unit)
	_phone_pos = Vector2(w - 60 * unit, 150 * unit)
	_view_pos = Vector2(w - 60 * unit, 100 * unit)
	_pause_pos = Vector2(w - 60 * unit, 50 * unit)
	_chat_pos = Vector2(55 * unit, h - 330 * unit)


func _draw() -> void:
	_draw_base(_move_center)
	if _joy_active:
		_draw_knob(_joy_knob)
	_draw_circle(_fire_pos, BTN_R["shoot"] * ui_scale, Color(0.9, 0.22, 0.22, 0.6))
	_draw_circle(_jump_pos, BTN_R["jump"] * ui_scale, Color(0.3, 0.8, 0.9, 0.55))
	_draw_circle(_sprint_pos, BTN_R["sprint"] * ui_scale, Color(0.9, 0.7, 0.3, 0.55))
	_draw_circle(_interact_pos, BTN_R["interact"] * ui_scale, Color(0.3, 0.9, 0.5, 0.55))
	_draw_circle(_light_pos, BTN_R["light_toggle"] * ui_scale, Color(0.9, 0.9, 0.5, 0.55))
	_draw_circle(_reload_pos, BTN_R["reload"] * ui_scale, Color(0.85, 0.6, 0.9, 0.55))
	_draw_circle(_phone_pos, BTN_R["phone"] * ui_scale, Color(0.5, 0.75, 1.0, 0.55))
	_draw_circle(_view_pos, BTN_R["view_toggle"] * ui_scale, Color(0.6, 0.9, 0.9, 0.55))
	_draw_circle(_chat_pos, BTN_R["chat"] * ui_scale, Color(0.7, 0.7, 0.9, 0.55))
	_draw_pause(_pause_pos, BTN_R["pause"] * ui_scale)
	_draw_label(_fire_pos, "FIRE")
	_draw_label(_jump_pos, "JUMP")
	_draw_label(_sprint_pos, "RUN")
	_draw_label(_interact_pos, "USE")
	_draw_label(_light_pos, "LIGHT")
	_draw_label(_reload_pos, "R")
	_draw_label(_phone_pos, "INV")
	_draw_label(_view_pos, "VIEW")
	_draw_label(_chat_pos, "CHAT")


func _draw_pause(center: Vector2, r: float) -> void:
	draw_circle(center, r, Color(0.1, 0.12, 0.15, 0.65))
	draw_arc(center, r, 0, TAU, 40, Color(1, 1, 1, 0.5), 2.0, true)
	var bw := r * 0.14
	var bh := r * 0.5
	draw_rect(Rect2(center.x - bw - bw * 0.5, center.y - bh / 2.0, bw, bh), Color(1, 1, 1, 0.9))
	draw_rect(Rect2(center.x + bw * 0.5, center.y - bh / 2.0, bw, bh), Color(1, 1, 1, 0.9))


func _draw_label(center: Vector2, text: String) -> void:
	var font := ThemeDB.fallback_font
	var size := int(22)
	var color := Color(1, 1, 1, 0.95)
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
	draw_string(font, Vector2(center.x - w / 2.0, center.y + size * 0.35), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)


func _draw_base(center: Vector2) -> void:
	draw_circle(center, BASE_RADIUS * ui_scale, Color(1, 1, 1, 0.10))
	draw_arc(center, BASE_RADIUS * ui_scale, 0, TAU, 48, Color(1, 1, 1, 0.35), 3.0, true)


func _draw_knob(center: Vector2) -> void:
	draw_circle(center, 26 * ui_scale, Color(1, 1, 1, 0.32))


func _draw_circle(center: Vector2, r: float, color: Color) -> void:
	draw_circle(center, r, color)
	draw_arc(center, r, 0, TAU, 40, Color(1, 1, 1, 0.4), 2.0, true)


func _apply_move() -> void:
	Input.action_release("move_forward")
	Input.action_release("move_back")
	Input.action_release("move_left")
	Input.action_release("move_right")
	if _move_vec.y < -0.3:
		Input.action_press("move_forward")
	elif _move_vec.y > 0.3:
		Input.action_press("move_back")
	if _move_vec.x < -0.3:
		Input.action_press("move_left")
	elif _move_vec.x > 0.3:
		Input.action_press("move_right")


func _send_move() -> void:
	if world and world.has_method("_touch_move"):
		world._touch_move(_move_vec)


func _clear_input() -> void:
	_move_vec = Vector2.ZERO
	_joy_active = false
	if world and world.has_method("_touch_move"):
		world._touch_move(Vector2.ZERO)
	for act in ["move_forward", "move_back", "move_left", "move_right", "sprint", "jump", "shoot", "interact", "light_toggle", "reload", "view_toggle", "phone"]:
		Input.action_release(act)
	_held.clear()
	_moves.clear()
	_looks.clear()
