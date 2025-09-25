extends AudioStreamPlayer

@onready var audioplayer = $"."

func _input(event):
	if event.is_action_pressed("flashlight"):
		audioplayer.play()
