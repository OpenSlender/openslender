extends Node

# Server-authoritative game state management
# Tracks collectibles, validates pickups, and synchronizes state to all clients

const COLLECTIBLE_SCENE = preload("res://collectible.tscn")

# Configuration
@export var collectibles_to_spawn: int = 8  # How many collectibles to spawn from available spawn points

# Collectible tracking
var collectibles := {}  # {id: {position: Vector3, rotation: Vector3, collected: bool}}
var next_collectible_id := 0
var total_collectibles := 0
var collected_count := 0

# Game world reference
var game_world_scene: Node3D = null
var is_initialized := false

signal collectible_collected(id: int, new_count: int, total: int)

func _ready() -> void:
	# Server-only script
	if not multiplayer.is_server():
		queue_free()
		return

func initialize_game_world(world_scene_path: String = "res://test.tscn") -> void:
	if is_initialized:
		return

	print("[GameStateManager] Initializing game world...")

	# Load the game world scene to extract collectible positions
	var world_scene = load(world_scene_path)
	if world_scene == null:
		push_error("[GameStateManager] Failed to load world scene: %s" % world_scene_path)
		return

	# Instantiate and add to tree temporarily to read global positions
	var temp_world = world_scene.instantiate()
	add_child(temp_world)

	# Wait for nodes to be properly in tree
	await get_tree().process_frame

	_extract_collectible_positions(temp_world)

	# Remove from tree
	temp_world.queue_free()

	is_initialized = true
	total_collectibles = collectibles.size()
	print("[GameStateManager] Initialized with %d collectibles" % total_collectibles)

func _extract_collectible_positions(world_node: Node) -> void:
	# Find all collectible spawn points in the scene
	var spawn_point_nodes = _find_nodes_in_group(world_node, "collectible_spawn_point")

	if spawn_point_nodes.is_empty():
		push_warning("[GameStateManager] No collectible spawn points found in scene!")
		return

	print("[GameStateManager] Found %d spawn points, selecting %d for collectibles" % [spawn_point_nodes.size(), collectibles_to_spawn])

	# Shuffle spawn points for randomization
	spawn_point_nodes.shuffle()

	# Select the first N spawn points (or all if we have fewer than requested)
	var spawn_count = min(collectibles_to_spawn, spawn_point_nodes.size())

	for i in range(spawn_count):
		var spawn_point = spawn_point_nodes[i]
		var id = next_collectible_id
		next_collectible_id += 1

		collectibles[id] = {
			"position": spawn_point.global_position,
			"rotation": spawn_point.global_rotation,
			"collected": false
		}
		print("[GameStateManager] Registered collectible %d at %s (spawn point)" % [id, spawn_point.global_position])

func _find_nodes_in_group(node: Node, group_name: String) -> Array:
	var result := []

	# Check if current node is in the specified group
	if node.is_in_group(group_name):
		result.append(node)

	# Recursively check children
	for child in node.get_children():
		result.append_array(_find_nodes_in_group(child, group_name))

	return result

# Called when a new player connects - send them the full game state
func sync_game_state_to_player(peer_id: int) -> void:
	if not is_initialized:
		return

	print("[GameStateManager] Syncing game state to player %d" % peer_id)

	# Send spawn commands for all collectibles
	var collectible_sync = get_node_or_null("/root/CollectibleSync")
	if not collectible_sync:
		push_error("[GameStateManager] CollectibleSync autoload not found!")
		return

	print("[GameStateManager] Sending %d collectible spawn commands to peer %d" % [collectibles.size(), peer_id])

	for collectible_id in collectibles.keys():
		var data = collectibles[collectible_id]
		print("[GameStateManager] Sending spawn RPC for collectible %d to peer %d at position %s" % [collectible_id, peer_id, data.position])
		collectible_sync.rpc_id(peer_id, "spawn_collectible", collectible_id, data.position, data.rotation)

		# If already collected, immediately send collection event
		if data.collected:
			collectible_sync.rpc_id(peer_id, "collectible_collected", collectible_id, -1, collected_count, total_collectibles)

	# Send current collectible count to GameManager
	if GameManager:
		GameManager.rpc_id(peer_id, "update_collectible_count", collected_count, total_collectibles)

# RPC: Client requests to pick up a collectible
@rpc("any_peer", "call_remote", "reliable")
func request_collectible_pickup(collectible_id: int) -> void:
	var peer_id = multiplayer.get_remote_sender_id()

	if not is_initialized:
		print("[GameStateManager] Pickup request rejected - game not initialized")
		return

	if not collectibles.has(collectible_id):
		print("[GameStateManager] Invalid collectible ID: %d from peer %d" % [collectible_id, peer_id])
		return

	if collectibles[collectible_id].collected:
		print("[GameStateManager] Collectible %d already collected" % collectible_id)
		return

	# Mark as collected
	collectibles[collectible_id].collected = true
	collected_count += 1

	print("[GameStateManager] Player %d collected collectible %d (%d/%d)" % [peer_id, collectible_id, collected_count, total_collectibles])

	# Broadcast to all clients via GameManager
	if GameManager:
		print("[GameStateManager] Broadcasting to GameManager.on_collectible_collected")
		GameManager.rpc("on_collectible_collected", collectible_id, peer_id, collected_count, total_collectibles)

	# Broadcast collectible removal to all clients via CollectibleSync
	var collectible_sync = get_node_or_null("/root/CollectibleSync")
	if collectible_sync:
		print("[GameStateManager] Broadcasting collectible removal via CollectibleSync")
		collectible_sync.rpc("collectible_collected", collectible_id, peer_id, collected_count, total_collectibles)
	else:
		push_error("[GameStateManager] CollectibleSync not found for broadcasting collection!")

	# Emit signal for server-side logic
	collectible_collected.emit(collectible_id, collected_count, total_collectibles)

	# Check if all collectibles collected
	if collected_count >= total_collectibles:
		print("[GameStateManager] All collectibles collected!")
		if GameManager:
			GameManager.rpc("on_all_collectibles_collected")

func reset_game_state() -> void:
	for collectible_id in collectibles.keys():
		collectibles[collectible_id].collected = false
	collected_count = 0
	print("[GameStateManager] Game state reset")
