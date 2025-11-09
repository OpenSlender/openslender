extends Node3D

const PLAYER_SCENE: PackedScene = preload("res://CharacterScriptsAndScenes/player.tscn")
const COLLECTIBLE_SCENE: PackedScene = preload("res://collectible.tscn")
const SERVER_PEER_ID := 1

@onready var players_root: Node3D = $Players

var players: Dictionary = {}
var local_peer_id: int = 0
var local_player: CharacterBody3D
var tracked_peer_ids: Array = []
var collectibles: Dictionary = {}  # {id: NetworkedCollectible}
var collectibles_root: Node3D

func _ready() -> void:
	local_peer_id = multiplayer.get_unique_id()
	if tracked_peer_ids.is_empty():
		tracked_peer_ids = [local_peer_id]
	elif !tracked_peer_ids.has(local_peer_id):
		tracked_peer_ids.append(local_peer_id)

	# Create collectibles root node
	collectibles_root = Node3D.new()
	collectibles_root.name = "Collectibles"
	add_child(collectibles_root)

	call_deferred("_sync_players")

func update_player_list(peer_ids: Array) -> void:
	if peer_ids.is_empty():
		peer_ids = [local_peer_id]
	if !peer_ids.has(local_peer_id):
		peer_ids.append(local_peer_id)
	tracked_peer_ids = peer_ids.duplicate()
	if !is_inside_tree():
		call_deferred("_sync_players")
		return
	_sync_players()

func shutdown() -> void:
	if local_player:
		local_player.release_input_focus()
	for player in players.values():
		if is_instance_valid(player):
			player.queue_free()
	players.clear()
	local_player = null
	tracked_peer_ids.clear()

	# Clean up collectibles
	for collectible in collectibles.values():
		if is_instance_valid(collectible):
			collectible.queue_free()
	collectibles.clear()

func _sync_players() -> void:
	if !players_root:
		return
	var new_peers: Array = []
	for peer_id in tracked_peer_ids:
		if peer_id == SERVER_PEER_ID:
			continue
		if !players.has(peer_id):
			var player: CharacterBody3D = PLAYER_SCENE.instantiate()
			player.name = "Player_%d" % peer_id
			var is_local: bool = peer_id == local_peer_id
			player.set_network_identity(peer_id, is_local)
			player.position = _spawn_position_for(peer_id)
			players_root.add_child(player)
			players[peer_id] = player
			if is_local:
				local_player = player
			else:
				new_peers.append(peer_id)
	var to_remove: Array = []
	for peer_id in players.keys():
		if peer_id == local_peer_id:
			continue
		if peer_id not in tracked_peer_ids:
			to_remove.append(peer_id)
	for peer_id in to_remove:
		var removed_player: CharacterBody3D = players[peer_id]
		if is_instance_valid(removed_player):
			removed_player.queue_free()
		players.erase(peer_id)
	_update_remote_peer_lists()
	if local_player and new_peers.size() > 0:
		local_player.send_transform_to_peers(new_peers)

func _update_remote_peer_lists() -> void:
	var peer_ids := players.keys()
	for peer_id in peer_ids:
		var remote_ids: Array = []
		for other_id in peer_ids:
			if other_id == peer_id:
				continue
			if other_id == SERVER_PEER_ID:
				continue
			remote_ids.append(other_id)
		var player: CharacterBody3D = players[peer_id]
		player.set_remote_peer_ids(remote_ids)

func _spawn_position_for(peer_id: int) -> Vector3:
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	var angle := rng.randf_range(0.0, TAU)
	var radius := rng.randf_range(2.0, 6.0)
	return Vector3(cos(angle) * radius, 1.6, sin(angle) * radius)

# Network RPC handlers for collectibles

@rpc("authority", "call_remote", "reliable")
func _rpc_spawn_collectible(collectible_id: int, position: Vector3, rotation: Vector3) -> void:
	# Security: Verify this RPC actually came from the server
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id != SERVER_PEER_ID:
		push_warning("[GameWorld] Security: Rejected _rpc_spawn_collectible from non-server peer %d (expected %d)" % [sender_id, SERVER_PEER_ID])
		return

	if collectibles.has(collectible_id):
		print("[GameWorld] Collectible %d already exists" % collectible_id)
		return

	print("[GameWorld] Spawning collectible %d at %s" % [collectible_id, position])

	# Load and attach the NetworkedCollectible script
	var networked_collectible_script = load("res://NetworkedCollectible.gd")

	# Instantiate collectible
	var collectible = COLLECTIBLE_SCENE.instantiate()
	collectible.name = "Collectible_%d" % collectible_id
	collectible.set_script(networked_collectible_script)

	# Add to scene first (required for global_position to work)
	collectibles_root.add_child(collectible)

	# Now set position and rotation
	collectible.global_position = position
	collectible.global_rotation = rotation

	# Set the collectible ID
	collectible.set_collectible_id(collectible_id)

	collectibles[collectible_id] = collectible
	print("[GameWorld] Collectible %d spawned successfully" % collectible_id)

@rpc("authority", "call_remote", "reliable")
func _rpc_collectible_collected(collectible_id: int, collector_peer_id: int, new_count: int, total: int) -> void:
	# Security: Verify this RPC actually came from the server
	var sender_id = multiplayer.get_remote_sender_id()
	if sender_id != SERVER_PEER_ID:
		push_warning("[GameWorld] Security: Rejected _rpc_collectible_collected from non-server peer %d (expected %d)" % [sender_id, SERVER_PEER_ID])
		return

	print("[GameWorld] Collectible %d collected by player %d (count: %d/%d)" % [collectible_id, collector_peer_id, new_count, total])

	# Remove the collectible from the scene
	if collectibles.has(collectible_id):
		print("[GameWorld] Found collectible %d in dictionary, removing..." % collectible_id)
		var collectible = collectibles[collectible_id]
		if is_instance_valid(collectible):
			print("[GameWorld] Collectible is valid, calling confirm_collection()")
			collectible.confirm_collection()
		else:
			print("[GameWorld] ERROR: Collectible %d is not valid" % collectible_id)
		collectibles.erase(collectible_id)
	else:
		print("[GameWorld] ERROR: Collectible %d not found in dictionary. Available IDs: %s" % [collectible_id, collectibles.keys()])
