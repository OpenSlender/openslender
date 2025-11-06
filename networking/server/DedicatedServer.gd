extends Node

const DEFAULT_PORT = 7777
const MAX_PLAYERS = 10

var peer: ENetMultiplayerPeer
var connected_players := {}

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

func start_server(port: int = DEFAULT_PORT, max_players: int = MAX_PLAYERS) -> bool:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, max_players)
	
	if error != OK:
		push_error("Failed to create server: %s" % error)
		return false
	
	multiplayer.multiplayer_peer = peer
	print("Server started on port %d" % port)
	return true

func stop_server() -> void:
	if peer:
		peer.close()
		connected_players.clear()
		print("Server stopped")

func _on_player_connected(peer_id: int) -> void:
	print("Player connected: %d" % peer_id)
	connected_players[peer_id] = {
		"id": peer_id,
		"connected_at": Time.get_ticks_msec()
	}
	player_connected.emit(peer_id)

func _on_player_disconnected(peer_id: int) -> void:
	print("Player disconnected: %d" % peer_id)
	connected_players.erase(peer_id)
	player_disconnected.emit(peer_id)

func get_connected_player_count() -> int:
	return connected_players.size()

func get_connected_player_ids() -> Array:
	return connected_players.keys()

