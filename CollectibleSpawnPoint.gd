class_name CollectibleSpawnPoint
extends Node3D

# Marker node for potential collectible spawn locations
# The server will randomly select from available spawn points to spawn collectibles

@export var weight: float = 1.0  # Higher weight = more likely to be chosen (for future weighted random)

func _enter_tree() -> void:
	add_to_group("collectible_spawn_point")

func _ready() -> void:
	# Make invisible in game (spawn points are only markers)
	visible = false

	# In editor, we'll still see the Node3D gizmo for positioning
	print("[CollectibleSpawnPoint] Spawn point registered at position: %s" % global_position)
