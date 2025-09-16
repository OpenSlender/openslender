extends Node

@export var total_collectibles: int = 0
@export var collected: int = 0

signal collectible_collected(collected: int, total_collectibles: int)
signal all_collectibles_collected

func _ready() -> void:
	call_deferred("initialize_collectibles")

func initialize_collectibles() -> void:
	if total_collectibles == 0:
		total_collectibles = get_tree().get_nodes_in_group("collectible").size()
	_emit_collectible_collected()

func reset_collectibles() -> void:
	collected = 0
	_emit_collectible_collected()

func collect_collectible() -> void:
	if collected >= total_collectibles:
		return
	collected += 1
	_emit_collectible_collected()
	if collected >= total_collectibles:
		emit_signal("all_collectibles_collected")

func _emit_collectible_collected() -> void:
	emit_signal("collectible_collected", collected, total_collectibles)
