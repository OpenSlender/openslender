class_name PlayerUtils
extends RefCounted

## Utility functions for player-related operations

## Finds the first CharacterBody3D ancestor that has multiplayer methods
## Returns null if no player ancestor is found
static func find_player_ancestor(node: Node) -> CharacterBody3D:
	var current_node = node.get_parent()
	while current_node != null:
		if current_node is CharacterBody3D and current_node.has_method("send_transform_to_peers"):
			return current_node
		current_node = current_node.get_parent()
	return null
