extends Node

const DEFAULT_PORT = 7777
const MAX_PLAYERS = 10

var peer: ENetMultiplayerPeer
var connected_players := {}
var game_state_manager: Node = null

signal player_connected(peer_id: int)
signal player_disconnected(peer_id: int)

func _ready() -> void:
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)

	# Create GameStateManager
	var GameStateManagerScript = load("res://networking/server/GameStateManager.gd")
	if not GameStateManagerScript:
		push_error("[DedicatedServer] Failed to load GameStateManager script")
		get_tree().quit(1)
		return

	game_state_manager = GameStateManagerScript.new()
	if not game_state_manager:
		push_error("[DedicatedServer] Failed to instantiate GameStateManager")
		get_tree().quit(1)
		return

	game_state_manager.name = "GameStateManager"
	add_child(game_state_manager)

	# Register with NetworkRegistry for stable discovery
	if has_node("/root/NetworkRegistry"):
		get_node("/root/NetworkRegistry").register_game_state_manager(game_state_manager)
	else:
		push_warning("[DedicatedServer] NetworkRegistry not found, GameStateManager not registered")

func _exit_tree() -> void:
	# Unregister from NetworkRegistry on cleanup
	if has_node("/root/NetworkRegistry"):
		get_node("/root/NetworkRegistry").unregister_game_state_manager()

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

	# Initialize game world when first player connects
	if connected_players.size() == 1 and game_state_manager:
		print("First player connected - initializing game world")
		await game_state_manager.initialize_game_world()

	# Sync game state to the newly connected player
	if game_state_manager:
		game_state_manager.sync_game_state_to_player(peer_id)

	player_connected.emit(peer_id)

func _on_player_disconnected(peer_id: int) -> void:
	print("Player disconnected: %d" % peer_id)
	connected_players.erase(peer_id)
	player_disconnected.emit(peer_id)

func get_connected_player_count() -> int:
	return connected_players.size()

func get_connected_player_ids() -> Array:
	return connected_players.keys()

