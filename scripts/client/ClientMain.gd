extends Node

const PORT: int = 3001
const INPUT_SEND_RATE: float = 0.05
const INTERPOLATION_SPEED: float = 15.0

var server_ip: String = "127.0.0.1"
var client: ENetMultiplayerPeer
var connected := false

var local_player: CharacterBody3D = null
var networked_players: Dictionary[Variant, Variant] = {}
var networked_players_targets: Dictionary[Variant, Variant] = {}
var monster_node: CharacterBody3D = null
var collectibles_nodes: Dictionary[Variant, Variant] = {}
var input_timer: Timer

@onready var connection_ui: Panel = $UI/ConnectionPanel
@onready var game_ui: Panel = $UI/GamePanel

func _ready() -> void:
	setup_connection_ui()

	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	setup_input_timer()
	
	call_deferred("load_game_map")

func load_game_map() -> void:
	print("Loading game map on server...")
	var game_scene: PackedScene = load(("res://test.tscn"))
	var game_instance: Node = game_scene.instantiate()
	get_tree().root.add_child(game_instance)
	
	call_deferred("")

func _process(delta: float) -> void:
	interpolate_networked_players(delta)

func setup_connection_ui() -> void:
	connection_ui.show()
	game_ui.hide()

	$UI/ConnectionPanel/ConnectButton.pressed.connect(_on_connect_pressed)
	$UI/ConnectionPanel/IPInput.text = server_ip

func _on_connect_pressed() -> void:
	var ip: String = $UI/ConnectionPanel/IPInput.text
	connect_to_server(ip)

func connect_to_server(ip: String) -> void:
	client = ENetMultiplayerPeer.new()
	var result: int = client.create_client(ip, PORT)

	if result != OK:
		show_error("Failed to connect to server")
		return

	multiplayer.multiplayer_peer = client
	print("Connecting to server at ", ip, " on port ", PORT)

	$UI/ConnectionPanel/StatusLabel.text = "Connecting..."

func _on_connection_failed() -> void:
	print("Failed to connect to server")
	show_error("Please check the server IP and port")

func _on_connected_to_server() -> void:
	print("Successfully connected to server")
	connected = true

	connection_ui.hide()
	game_ui.show()
	
	# Load the game world
	var game_scene: PackedScene = load("res://test.tscn")
	var game_instance: Node = game_scene.instantiate()
	get_tree().root.add_child(game_instance)
	
	call_deferred("find_local_player")
		
func _on_server_disconnected() -> void:
	print("Disconnected from server")
	connected = false
	
	for player_id in networked_players.keys():
		remove_networked_player(player_id)
	networked_players.clear()

	connection_ui.show()
	game_ui.hide()
	show_error("Disconnected from server")

func send_input(input: Dictionary) -> void:
	if connected and multiplayer.has_multiplayer_peer():
		rpc_id(1, "player_input", input)

@rpc("any_peer", "call_local", "reliable")
func player_input(_input_data: Dictionary) -> void:
	pass

@rpc("authority", "call_local", "reliable")
func update_game_state(state: Dictionary) -> void:
	apply_game_state(state)

@rpc("any_peer")
func on_player_joined(id: int) -> void:
	print("Player ", id, " joined")

@rpc("any_peer")
func on_player_left(id: int) -> void:
	print("Player ", id, " left")

@rpc("authority", "call_local", "reliable")
func set_spawn_position(position: Vector3) -> void:
	print("Received spawn position: ", position)
	if local_player and is_instance_valid(local_player):
		local_player.global_position = position
		print("Moved local player to spawn position")
	else:
		await get_tree().create_timer(0.1).timeout
		if local_player and is_instance_valid(local_player):
			local_player.global_position = position
			print("Moved local player to spawn position (delayed)")

func show_error(message: String) -> void:
	$UI/ConnectionPanel/StatusLabel.text = message

func setup_input_timer() -> void:
	input_timer = Timer.new()
	input_timer.wait_time = INPUT_SEND_RATE
	input_timer.autostart = true
	input_timer.timeout.connect(send_player_input)
	add_child(input_timer)

func send_player_input() -> void:
	if not connected or local_player == null:
		return
	
	var flashlight: Node = local_player.get_node_or_null("CameraPivot/Camera3D/SpotLight3D")
	var flashlight_on: bool = false
	if flashlight and flashlight is SpotLight3D:
		flashlight_on = flashlight.visible
	
	# Only send body Y rotation (left/right), not camera pitch (up/down)
	var body_rotation: Vector3 = Vector3(local_player.rotation.x, local_player.rotation.y, 0)
	
	var input_data: Dictionary[Variant, Variant] = {
		"position": local_player.global_position,
		"rotation": body_rotation,
		"velocity": local_player.velocity,
		"state": local_player.state_machine.get_current_state_name() if local_player.state_machine else "idle",
		"flashlight_on": flashlight_on
	}
	
	send_input(input_data)

func interpolate_networked_players(delta: float) -> void:
	for player_id in networked_players.keys():
		if not networked_players_targets.has(player_id):
			continue
		
		var player_node = networked_players[player_id]
		if not player_node or not is_instance_valid(player_node):
			continue
		
		var target_data = networked_players_targets[player_id]
		if not target_data.has("position") or not target_data.has("rotation"):
			continue
		
		# Smoothly interpolate position
		var target_pos = target_data["position"]
		player_node.global_position = player_node.global_position.lerp(target_pos, INTERPOLATION_SPEED * delta)
		
		# Smoothly interpolate rotation (use slerp for smooth rotation)
		var target_rot = target_data["rotation"]
		player_node.global_rotation.x = lerp_angle(player_node.global_rotation.x, target_rot.x, INTERPOLATION_SPEED * delta)
		player_node.global_rotation.y = lerp_angle(player_node.global_rotation.y, target_rot.y, INTERPOLATION_SPEED * delta)
		player_node.global_rotation.z = lerp_angle(player_node.global_rotation.z, target_rot.z, INTERPOLATION_SPEED * delta)

func apply_game_state(state: Dictionary) -> void:
	if state.has("players"):
		update_networked_players(state["players"])
	
	if state.has("monster"):
		update_monster(state["monster"])
	
	if state.has("collectibles"):
		update_collectibles(state["collectibles"])

func update_networked_players(players_data: Dictionary) -> void:
	var my_id: int = multiplayer.get_unique_id()
	
	for player_id in players_data.keys():
		if player_id == my_id:
			continue
		
		var player_state = players_data[player_id]
		
		if not networked_players.has(player_id):
			spawn_networked_player(player_id, player_state)
		else:
			var player_node = networked_players[player_id]
			if player_node and is_instance_valid(player_node):
				# Store target position and rotation for interpolation
				if not networked_players_targets.has(player_id):
					networked_players_targets[player_id] = {}
				
				networked_players_targets[player_id]["position"] = player_state.get("position", Vector3.ZERO)
				networked_players_targets[player_id]["rotation"] = player_state.get("rotation", Vector3.ZERO)
				
				# Update flashlight state immediately (no need to interpolate)
				var flashlight = player_node.get_node_or_null("CameraPivot/Camera3D/SpotLight3D")
				if flashlight and flashlight is SpotLight3D:
					flashlight.visible = player_state.get("flashlight_on", false)
	
	var to_remove: Array[Variant] = []
	for player_id in networked_players.keys():
		if not players_data.has(player_id):
			to_remove.append(player_id)
	
	for player_id in to_remove:
		remove_networked_player(player_id)

func spawn_networked_player(player_id: int, player_state: Dictionary) -> void:
	var player_scene: PackedScene = preload("res://CharacterScriptsAndScenes/player.tscn")
	var player_instance: Node = player_scene.instantiate()
	
	player_instance.name = "Player_" + str(player_id)
	
	if "is_local" in player_instance:
		player_instance.is_local = false
	
	var camera: Node = player_instance.get_node_or_null("CameraPivot/Camera3D")
	if camera:
		camera.current = false
	
	get_tree().root.add_child(player_instance)
	
	player_instance.global_position = player_state.get("position", Vector3.ZERO)
	player_instance.global_rotation = player_state.get("rotation", Vector3.ZERO)
	
	networked_players[player_id] = player_instance
	print("Spawned networked player: ", player_id)

func remove_networked_player(player_id: int) -> void:
	if networked_players.has(player_id):
		var player_node = networked_players[player_id]
		if is_instance_valid(player_node):
			player_node.queue_free()
		networked_players.erase(player_id)
		networked_players_targets.erase(player_id)
		print("Removed networked player: ", player_id)

func update_monster(monster_data: Dictionary) -> void:
	if monster_data.is_empty():
		return
	
	if monster_node == null or not is_instance_valid(monster_node):
		var monsters: Array[Node] = get_tree().get_nodes_in_group("monster")
		if monsters.size() > 0:
			monster_node = monsters[0]
	
	if monster_node and is_instance_valid(monster_node):
		monster_node.global_position = monster_data.get("position", Vector3.ZERO)
		monster_node.global_rotation = monster_data.get("rotation", Vector3.ZERO)

func update_collectibles(collectibles_data: Dictionary) -> void:
	if collectibles_nodes.is_empty():
		var collectibles: Array[Node] = get_tree().get_nodes_in_group("collectible")
		for i in range(collectibles.size()):
			collectibles_nodes[i] = collectibles[i]
	
	for collectible_id in collectibles_data.keys():
		var is_collected = collectibles_data[collectible_id]
		if collectibles_nodes.has(collectible_id):
			var collectible = collectibles_nodes[collectible_id]
			if is_instance_valid(collectible):
				collectible.visible = not is_collected

func find_local_player() -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		local_player = players[0]
		if "is_local" in local_player:
			local_player.is_local = true
		print("Found local player")
