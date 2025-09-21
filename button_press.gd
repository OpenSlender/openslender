extends AnimationPlayer


func _input(event):
	if event.is_action_pressed("flashlight"):
		$".".play("button_push")
