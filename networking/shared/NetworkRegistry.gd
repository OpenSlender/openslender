extends Node

## NetworkRegistry - Autoload singleton for stable network component discovery
## Provides a centralized registry for key network components to avoid fragile scene tree traversal

var game_state_manager: Node = null

func register_game_state_manager(manager: Node) -> void:
	if game_state_manager and game_state_manager != manager:
		push_warning("[NetworkRegistry] GameStateManager already registered, replacing")
	game_state_manager = manager
	print("[NetworkRegistry] GameStateManager registered: %s" % manager)

func unregister_game_state_manager() -> void:
	game_state_manager = null
	print("[NetworkRegistry] GameStateManager unregistered")

func get_game_state_manager() -> Node:
	return game_state_manager
