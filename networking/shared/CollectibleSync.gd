extends Node

# Network synchronization layer for collectibles
# This autoload exists on both server and client to relay collectible RPCs

## Server → Client RPCs

@rpc("authority", "call_remote", "reliable")
func spawn_collectible(collectible_id: int, position: Vector3, rotation: Vector3) -> void:
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
		print("[CollectibleSync] ERROR: request_pickup called on client (should only run on server)")
		return

	print("[CollectibleSync] Server received pickup request for collectible %d from peer %d" % [collectible_id, multiplayer.get_remote_sender_id()])

	# Debug: Print the scene tree structure
	var root_children = get_tree().root.get_children()
	print("[CollectibleSync] Root children: ", root_children)

	# Find the GameStateManager in the server scene
	# The server scene structure is: ServerLauncher -> DedicatedServer -> GameStateManager
	var dedicated_server = get_tree().root.get_node_or_null("ServerLauncher/DedicatedServer")
	if not dedicated_server:
		print("[CollectibleSync] ServerLauncher/DedicatedServer not found, trying just DedicatedServer")
		dedicated_server = get_tree().root.get_node_or_null("DedicatedServer")

	if not dedicated_server:
		# Try to find it in root children directly
		print("[CollectibleSync] Searching for DedicatedServer in root children...")
		for child in root_children:
			print("[CollectibleSync] Checking child: %s (type: %s)" % [child.name, child.get_class()])
			if child.name == "DedicatedServer":
				dedicated_server = child
				break
			# Check if it has a DedicatedServer child
			var sub_child = child.get_node_or_null("DedicatedServer")
			if sub_child:
				dedicated_server = sub_child
				print("[CollectibleSync] Found DedicatedServer as child of %s" % child.name)
				break

	if not dedicated_server:
		push_error("[CollectibleSync] Could not find DedicatedServer node anywhere")
		return

	print("[CollectibleSync] Found DedicatedServer: %s" % dedicated_server)

	var game_state_manager = dedicated_server.get_node_or_null("GameStateManager")
	if game_state_manager and game_state_manager.has_method("request_collectible_pickup"):
		game_state_manager.request_collectible_pickup(collectible_id)
	else:
		push_error("[CollectibleSync] GameStateManager not found or missing method")
		print("[CollectibleSync] DedicatedServer children: %s" % dedicated_server.get_children())
