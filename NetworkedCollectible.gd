class_name NetworkedCollectible
extends Collectible

# Network-aware collectible that communicates with server for pickup validation

var collectible_id: int = -1
var is_network_spawned := false
var _pickup_pending := false  # Prevents double-pickup while waiting for server
var _pickup_timeout_timer: Timer = null

const SERVER_PEER_ID := 1
const PICKUP_TIMEOUT_SECONDS := 3.0

func set_collectible_id(id: int) -> void:
	collectible_id = id
	is_network_spawned = true
	print("[NetworkedCollectible] Assigned ID: %d at position %s" % [collectible_id, global_position])

# Override try_pickup to send request to server instead of local collection
func try_pickup() -> void:
	# Validate collectible_id has been assigned before proceeding
	if collectible_id == -1:
		push_warning("[NetworkedCollectible] Attempted to pickup collectible with unassigned ID (-1)")
		return

	print("[NetworkedCollectible] try_pickup() called for ID %d (collected=%s, pending=%s, network_spawned=%s)" % [collectible_id, _collected, _pickup_pending, is_network_spawned])

	if _collected or _pickup_pending:
		print("[NetworkedCollectible] Pickup already in progress for ID %d" % collectible_id)
		return

	if not is_network_spawned:
		push_warning("[NetworkedCollectible] Attempted pickup of non-networked collectible ID %d" % collectible_id)
		return

	if not multiplayer.has_multiplayer_peer():
		push_warning("[NetworkedCollectible] No multiplayer peer connected for ID %d" % collectible_id)
		return

	print("[NetworkedCollectible] Processing pickup request for collectible %d" % collectible_id)

	# Mark as pending to prevent double-pickup (don't set _collected yet)
	_pickup_pending = true
	set_highlighted(false)
	monitoring = false  # Stop detecting collisions immediately

	# Hide immediately for instant client feedback (same as parent class approach)
	# Server still has authority - if pickup fails, server can respawn it
	visible = false

	print("[NetworkedCollectible] Collectible %d hidden immediately (visible=%s)" % [collectible_id, visible])

	# Send pickup request to server via CollectibleSync
	var collectible_sync = get_node_or_null("/root/CollectibleSync")
	if collectible_sync:
		print("[NetworkedCollectible] Sending RPC for collectible %d" % collectible_id)
		collectible_sync.rpc_id(SERVER_PEER_ID, "request_pickup", collectible_id)

		# Start timeout timer to recover if server doesn't respond
		_start_pickup_timeout()
	else:
		push_error("[NetworkedCollectible] CollectibleSync autoload not found!")
		_cancel_pickup_request()  # Reset state if request failed

# Called directly (not RPC) to confirm collection
func confirm_collection() -> void:
	if _collected:
		print("[NetworkedCollectible] Collection already confirmed for ID %d, ignoring" % collectible_id)
		return

	print("[NetworkedCollectible] Confirming collection for ID %d (server confirmation)" % collectible_id)

	# Cancel timeout timer since server confirmed
	_cancel_pickup_timeout()

	_collected = true

	# Visual hiding already done in try_pickup() for instant client feedback
	# This method just handles final server confirmation and cleanup

	if one_shot:
		# queue_free() handles removal automatically, no need for manual remove_child
		print("[NetworkedCollectible] Queuing collectible %d for removal" % collectible_id)
		queue_free()

func _start_pickup_timeout() -> void:
	_cancel_pickup_timeout()  # Clear any existing timer

	_pickup_timeout_timer = Timer.new()
	_pickup_timeout_timer.wait_time = PICKUP_TIMEOUT_SECONDS
	_pickup_timeout_timer.one_shot = true
	_pickup_timeout_timer.timeout.connect(_on_pickup_timeout)
	add_child(_pickup_timeout_timer)
	_pickup_timeout_timer.start()

func _cancel_pickup_timeout() -> void:
	if _pickup_timeout_timer:
		_pickup_timeout_timer.queue_free()
		_pickup_timeout_timer = null

func _on_pickup_timeout() -> void:
	if _collected:
		return  # Server confirmed in time, nothing to do

	push_warning("[NetworkedCollectible] Pickup request timed out for collectible %d, restoring" % collectible_id)
	_cancel_pickup_request()

func _cancel_pickup_request() -> void:
	# Safety check: don't access node properties if removed during timeout
	if not is_inside_tree() or is_queued_for_deletion():
		_cancel_pickup_timeout()
		return

	_pickup_pending = false
	visible = true
	monitoring = true
	set_highlighted(false)
	_cancel_pickup_timeout()
