extends AudioStreamPlayer

@onready var audioplayer = $"."
var player: CharacterBody3D = null

func _ready():
	player = PlayerUtils.find_player_ancestor(self)

func _input(event):
	if player == null or !player.is_local_player:
		return
	if event.is_action_pressed("flashlight"):
		audioplayer.play()
