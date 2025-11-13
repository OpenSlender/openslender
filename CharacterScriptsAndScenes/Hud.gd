extends Control

var _collectibles_label: Label
var _collectibles_panel: Panel

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	_collectibles_panel = get_node("CollectiblesPanel") as Panel
	_collectibles_label = get_node("CollectiblesPanel/VBoxContainer/CollectiblesLabel") as Label
	if Engine.has_singleton("GameManager") or typeof(GameManager) != TYPE_NIL:
		GameManager.connect("collectible_collected", Callable(self, "_on_collectible_collected"))
		GameManager.connect("all_collectibles_collected", Callable(self, "_on_all_collectibles_collected"))
		_on_collectible_collected(GameManager.collected, GameManager.total_collectibles)

func _on_collectible_collected(collected: int, total_collectibles: int) -> void:
	_collectibles_label.text = "%s/%s" % [collected, total_collectibles]

func _on_all_collectibles_collected() -> void:
	_collectibles_label.text = "You found all the collectibles!"
	# Resize panel to accommodate the longer message
	_collectibles_panel.offset_left = -220.0  # Wider (was -160.0)
	_collectibles_panel.offset_bottom = 120.0  # Taller (was 95.0)
