extends Node

const NetworkConstants = preload("res://networking/shared/NetworkConstants.gd")

var peer: ENetMultiplayerPeer
var connected := false
var server_address := NetworkConstants.DEFAULT_SERVER_ADDRESS
var server_port := NetworkConstants.DEFAULT_SERVER_PORT

signal connection_succeeded()
signal connection_failed()
signal server_disconnected()
signal player_list_updated(player_ids: Array)
var _cached_player_ids: Array = []

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

func connect_to_server(address: String, port: int) -> void:
	if connected:
		push_warning("Already connected to server")
		return
	
	server_address = address
	server_port = port
	
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	
	if error != OK:
		push_error("Failed to create client: %s" % error)
		connection_failed.emit()
		return
	
	multiplayer.multiplayer_peer = peer
	print("Attempting to connect to %s:%d" % [address, port])

func disconnect_from_server() -> void:
	if peer:
		peer.close()
		peer = null
	connected = false
	_cached_player_ids.clear()
	multiplayer.multiplayer_peer = null
	print("Disconnected from server")

func _on_connected_to_server() -> void:
	print("Successfully connected to server")
	connected = true
	connection_succeeded.emit()
	_request_player_list()

func _on_connection_failed() -> void:
	print("Failed to connect to server")
	connected = false
	peer = null
	_cached_player_ids.clear()
	connection_failed.emit()

func _on_server_disconnected() -> void:
	print("Disconnected from server")
	connected = false
	peer = null
	_cached_player_ids.clear()
	server_disconnected.emit()

func _on_player_connected(peer_id: int) -> void:
	print("Player connected: %d" % peer_id)
	_request_player_list()

func _on_player_disconnected(peer_id: int) -> void:
	print("Player disconnected: %d" % peer_id)
	_request_player_list()

func _request_player_list() -> void:
	if connected:
		var player_ids = multiplayer.get_peers()
		player_ids.append(multiplayer.get_unique_id())
		_cached_player_ids = player_ids.duplicate()
		player_list_updated.emit(player_ids)

func get_my_peer_id() -> int:
	if connected:
		return multiplayer.get_unique_id()
	return -1

func get_current_player_ids() -> Array:
	if _cached_player_ids.is_empty() and connected:
		var player_ids = multiplayer.get_peers()
		player_ids.append(multiplayer.get_unique_id())
		return player_ids
	return _cached_player_ids.duplicate()
