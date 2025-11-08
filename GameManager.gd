extends Node

@export var total_collectibles: int = 0
@export var collected: int = 0

signal collectible_collected(collected: int, total_collectibles: int)
signal all_collectibles_collected

var is_multiplayer_mode := false

func _ready() -> void:
	# Check if we're in multiplayer mode
	is_multiplayer_mode = multiplayer.has_multiplayer_peer()

	# Only initialize from scene in single-player mode
	if not is_multiplayer_mode:
		call_deferred("initialize_collectibles")

func initialize_collectibles() -> void:
	if total_collectibles == 0:
		total_collectibles = get_tree().get_nodes_in_group("collectible").size()
	_emit_collectible_collected()

func reset_collectibles() -> void:
	collected = 0
	_emit_collectible_collected()

func collect_collectible() -> void:
	# In multiplayer mode, server handles this through RPCs
	if is_multiplayer_mode:
		return

	if collected >= total_collectibles:
		return
	collected += 1
	_emit_collectible_collected()
	if collected >= total_collectibles:
		emit_signal("all_collectibles_collected")

func _emit_collectible_collected() -> void:
	emit_signal("collectible_collected", collected, total_collectibles)

# Network RPC handlers - called by server to update collectible state

@rpc("authority", "call_local", "reliable")
func update_collectible_count(new_collected: int, new_total: int) -> void:
	collected = new_collected
	total_collectibles = new_total
	print("[GameManager] Updated collectible count: %d/%d" % [collected, total_collectibles])
	_emit_collectible_collected()

@rpc("authority", "call_local", "reliable")
func on_collectible_collected(collectible_id: int, collector_peer_id: int, new_count: int, total: int) -> void:
	collected = new_count
	total_collectibles = total
	print("[GameManager] Collectible %d collected by player %d (%d/%d)" % [collectible_id, collector_peer_id, new_count, total])
	_emit_collectible_collected()

	if collected >= total_collectibles:
		emit_signal("all_collectibles_collected")

@rpc("authority", "call_local", "reliable")
func on_all_collectibles_collected() -> void:
	print("[GameManager] All collectibles collected!")
	emit_signal("all_collectibles_collected")
