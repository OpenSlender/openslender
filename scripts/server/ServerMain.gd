extends Node

const PORT: int = 3001
const MAX_CLIENTS: int = 10
const TICK_RATE: float = 0.05
const SPAWN_RADIUS: float = 5.0
const SPAWN_HEIGHT: float = 2.0

var server: ENetMultiplayerPeer
var connected_players: Dictionary[Variant, Variant] = {}
var player_states: Dictionary[Variant, Variant] = {}
var monster_state: Dictionary[Variant, Variant] = {}
var collectibles: Dictionary[Variant, Variant] = {}
var update_timer: Timer
var next_spawn_index: int = 0

func _ready() -> void:
	start_server()
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	setup_update_timer()
	
	call_deferred("load_game_map")
	
func load_game_map() -> void:
	print("Loading game map on server...")
	var game_scene: PackedScene = load("res://test.tscn")
	var game_instance = game_scene.instantiate()
	get_tree().root.add_child(game_instance)
	
	call_deferred("initialize_collectibles")
	
func initialize_collectibles() -> void:
	print("Initializing collectibles...")
	
	var collectible_nodes: Array[Node] = get_tree().get_nodes_in_group("collectibles")
	
	for i in range(collectible_nodes.size()):
		collectibles[i] = false
		
	if GameManager:
		GameManager.total_collectibles = collectibles.size()

func start_server() -> void:
	server = ENetMultiplayerPeer.new()
	var result: int = server.create_server(PORT, MAX_CLIENTS)
	if result != OK:
		print("Failed to create server on port ", PORT)
		get_tree().quit(1)
		return

	multiplayer.multiplayer_peer = server
	print("Server started successfully on port ", PORT)
	print("Waiting for clients...")

func _on_player_connected(id: int) -> void:
	print("Player ", id, " connected")
	connected_players[id] = {
		"id": id,
		"connected_at": Time.get_ticks_msec()
	}
	
	var spawn_pos: Vector3 = get_spawn_position(next_spawn_index)
	next_spawn_index += 1
	
	player_states[id] = {
		"position": spawn_pos,
		"rotation": Vector3.ZERO,
		"state": "idle",
		"flashlight_on": false
	}

	rpc_id(id, "set_spawn_position", spawn_pos)
	
	rpc("on_player_joined", id)

func get_spawn_position(index: int) -> Vector3:
	var angle: float = (index * TAU / 8.0)
	var x: float = cos(angle) * SPAWN_RADIUS
	var z: float = sin(angle) * SPAWN_RADIUS
	return Vector3(x, SPAWN_HEIGHT, z)

func _on_player_disconnected(id: int) -> void:
	print("Player ", id, " disconnected")
	if id in connected_players:
		connected_players.erase(id)
	
	if id in player_states:
		player_states.erase(id)

	rpc("on_player_left", id)

@rpc("any_peer", "call_local", "reliable")
func player_input(input_data: Dictionary) -> void:
	var sender_id: int = multiplayer.get_remote_sender_id()
	process_player_action(sender_id, input_data)

func broadcast_game_state() -> void:
	if connected_players.size() == 0:
		return
	
	var game_state: Dictionary = get_current_game_state()
	rpc("update_game_state", game_state)

func get_current_game_state() -> Dictionary:
	return {
		"tick": Time.get_ticks_msec(),
		"players": player_states,
		"monster": monster_state,
		"collectibles": collectibles
	}

func process_player_action(sender_id: int, input_data: Dictionary) -> void:
	if input_data.has("position") and input_data.has("rotation"):
		if not player_states.has(sender_id):
			player_states[sender_id] = {}
		
		player_states[sender_id]["position"] = input_data.get("position", Vector3.ZERO)
		player_states[sender_id]["rotation"] = input_data.get("rotation", Vector3.ZERO)
		player_states[sender_id]["state"] = input_data.get("state", "idle")
		player_states[sender_id]["flashlight_on"] = input_data.get("flashlight_on", false)

func setup_update_timer() -> void:
	update_timer = Timer.new()
	update_timer.wait_time = TICK_RATE
	update_timer.autostart = true
	update_timer.timeout.connect(broadcast_game_state)
	add_child(update_timer)

@rpc("any_peer")
func on_player_joined(_id: int) -> void:
	pass

@rpc("any_peer")
func on_player_left(_id: int) -> void:
	pass

@rpc("authority", "call_local", "reliable")
func update_game_state(_state: Dictionary) -> void:
	pass

@rpc("authority", "call_local", "reliable")
func set_spawn_position(_position: Vector3) -> void:
	pass
