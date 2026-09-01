extends Node

const DEFAULT_PORT := 25565
const DEFAULT_MAX_PLAYERS := 8

var _server_mode := false
var _client_mode := false
var pending_join_host := ""
var pending_join_port := 0


func reset() -> void:
	_server_mode = false
	_client_mode = false
	multiplayer.multiplayer_peer = null


func start_server(port: int, max_players: int) -> bool:
	reset()
	var p := ENetMultiplayerPeer.new()
	var err := p.create_server(port, max_players)
	if err != OK:
		push_error("Net: failed to start server (port %d): %d" % [port, err])
		return false
	multiplayer.multiplayer_peer = p
	_server_mode = true
	return true


func start_client(host: String, port: int) -> bool:
	reset()
	var p := ENetMultiplayerPeer.new()
	var err := p.create_client(host, port)
	if err != OK:
		push_error("Net: failed to connect to %s:%d: %d" % [host, port, err])
		return false
	multiplayer.multiplayer_peer = p
	_client_mode = true
	return true


func is_server() -> bool:
	return _server_mode


func is_client() -> bool:
	return _client_mode


func in_network() -> bool:
	return _server_mode or _client_mode


func my_id() -> int:
	return multiplayer.get_unique_id()
