class_name NetworkedCollectible
extends Collectible

# Network-aware collectible that communicates with server for pickup validation

var collectible_id: int = -1
var is_network_spawned := false
var _pickup_pending := false  # Prevents double-pickup while waiting for server

const SERVER_PEER_ID := 1

func set_collectible_id(id: int) -> void:
	collectible_id = id
	is_network_spawned = true
	print("[NetworkedCollectible] Assigned ID: %d at position %s" % [collectible_id, global_position])

# Override try_pickup to send request to server instead of local collection
func try_pickup() -> void:
	if _collected or _pickup_pending:
		print("[NetworkedCollectible] Pickup already in progress for ID %d" % collectible_id)
		return

	if not is_network_spawned:
		push_warning("[NetworkedCollectible] Attempted pickup of non-networked collectible")
		return

	if not multiplayer.has_multiplayer_peer():
		push_warning("[NetworkedCollectible] No multiplayer peer connected")
		return

	print("[NetworkedCollectible] Requesting pickup of collectible %d" % collectible_id)

	# Mark as pending to prevent double-pickup (don't set _collected yet)
	_pickup_pending = true
	set_highlighted(false)
	monitoring = false  # Stop detecting collisions immediately

	# Immediately hide the collectible for instant client feedback
	# (Server still has authority - if pickup fails, server can respawn it)

	# Hide the mesh instance explicitly
	if _mesh_instance:
		_mesh_instance.visible = false

	# Hide the outline instance explicitly
	if _outline_instance:
		_outline_instance.visible = false

	# Hide all children
	for child in get_children():
		if child is VisualInstance3D or child is MeshInstance3D:
			child.visible = false

	# Hide self
	visible = false

	print("[NetworkedCollectible] Collectible %d hidden immediately (client-side)" % collectible_id)

	# Send pickup request to server via CollectibleSync
	var collectible_sync = get_node_or_null("/root/CollectibleSync")
	if collectible_sync:
		collectible_sync.rpc_id(SERVER_PEER_ID, "request_pickup", collectible_id)
	else:
		push_error("[NetworkedCollectible] CollectibleSync autoload not found!")
		_pickup_pending = false  # Reset if request failed

# Called directly (not RPC) to confirm collection
func confirm_collection() -> void:
	if _collected:
		print("[NetworkedCollectible] Collection already confirmed for ID %d, ignoring" % collectible_id)
		return

	print("[NetworkedCollectible] Confirming collection for ID %d (server confirmation)" % collectible_id)

	_collected = true

	# Visual hiding already done in try_pickup() for instant client feedback
	# This method just handles final server confirmation and cleanup

	if one_shot:
		# Remove from parent immediately, then queue free
		print("[NetworkedCollectible] Removing collectible %d from scene tree" % collectible_id)
		if get_parent():
			get_parent().remove_child(self)
		queue_free()
