extends Node

# Network synchronization layer for collectibles
# This autoload exists on both server and client to relay collectible RPCs

## Server → Client RPCs

@rpc("authority", "call_remote", "reliable")
func spawn_collectible(collectible_id: int, position: Vector3, rotation: Vector3) -> void:
	# Security: Verify this RPC came from the server (authority)
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id != 1:  # SERVER_PEER_ID is always 1
		push_warning("[CollectibleSync] Security: Rejected spawn_collectible from non-server peer %d" % sender_id)
		return

	# Called on client - route to GameWorld
	print("[CollectibleSync] Received spawn_collectible RPC for ID %d at %s" % [collectible_id, position])
	var game_world = get_node_or_null("/root/NetworkGameWorld")
	if game_world and game_world.has_method("_rpc_spawn_collectible"):
		print("[CollectibleSync] Routing to GameWorld")
		game_world._rpc_spawn_collectible(collectible_id, position, rotation)
	else:
		print("[CollectibleSync] ERROR: GameWorld not found or missing _rpc_spawn_collectible method")
		print("[CollectibleSync] GameWorld node: %s" % game_world)
		if game_world:
			print("[CollectibleSync] Has method: %s" % game_world.has_method("_rpc_spawn_collectible"))

@rpc("authority", "call_remote", "reliable")
func collectible_collected(collectible_id: int, collector_peer_id: int, new_count: int, total: int) -> void:
	# Security: Verify this RPC came from the server (authority)
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id != 1:  # SERVER_PEER_ID is always 1
		push_warning("[CollectibleSync] Security: Rejected collectible_collected from non-server peer %d" % sender_id)
		return

	# Called on client - route to GameWorld
	print("[CollectibleSync] Received collectible_collected RPC for ID %d (collected by peer %d)" % [collectible_id, collector_peer_id])
	var game_world = get_node_or_null("/root/NetworkGameWorld")
	if game_world and game_world.has_method("_rpc_collectible_collected"):
		print("[CollectibleSync] Routing to GameWorld._rpc_collectible_collected")
		game_world._rpc_collectible_collected(collectible_id, collector_peer_id, new_count, total)
	else:
		print("[CollectibleSync] ERROR: GameWorld not found or missing method")
		print("[CollectibleSync] GameWorld: %s" % game_world)

## Client → Server RPCs

@rpc("any_peer", "call_remote", "reliable")
func request_pickup(collectible_id: int) -> void:
	# This RPC is called ON THE SERVER by a client
	# Only process if we're the server
	if not multiplayer.is_server():
		push_error("[CollectibleSync] request_pickup called on client (should only run on server)")
		return

	print("[CollectibleSync] Server received pickup request for collectible %d from peer %d" % [collectible_id, multiplayer.get_remote_sender_id()])

	# Use NetworkRegistry for stable component discovery
	var game_state_manager = NetworkRegistry.get_game_state_manager()
	if not game_state_manager:
		push_error("[CollectibleSync] GameStateManager not registered in NetworkRegistry")
		return

	if not game_state_manager.has_method("request_collectible_pickup"):
		push_error("[CollectibleSync] GameStateManager missing request_collectible_pickup method")
		return

	game_state_manager.request_collectible_pickup(collectible_id)
