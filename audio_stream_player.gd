extends AudioStreamPlayer

@onready var audioplayer = $"."
var player: CharacterBody3D = null

func _ready():
	player = _find_player_ancestor()

func _find_player_ancestor() -> CharacterBody3D:
	var current_node = get_parent()
	while current_node != null:
		if current_node is CharacterBody3D and current_node.has_method("send_transform_to_peers"):
			return current_node
		current_node = current_node.get_parent()
	return null

func _input(event):
	if player == null or !player.is_local_player:
		return
	if event.is_action_pressed("flashlight"):
		audioplayer.play()
