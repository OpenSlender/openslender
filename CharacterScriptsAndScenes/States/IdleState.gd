class_name IdleState
extends "res://CharacterScriptsAndScenes/States/BaseLocomotionState.gd"

func physics_update(player, delta: float) -> void:
	var velocity: Vector3 = player.velocity
	var res := _handle_airborne(player, velocity, delta)
	velocity = res.velocity
	if res.handled:
		player.velocity = velocity
		player.move_and_slide()
		return

	var input_dir := _read_input_2d()
	if _try_start_jump(player):
		return
	if _try_start_crouch(player):
		return
	if input_dir.length_squared() > player.settings.input_threshold_squared:
		if Input.is_action_pressed("run"):
			player.state_machine.change_state(StateNames.States.Running, player)
			return
		player.state_machine.change_state(StateNames.States.Walking, player)
		return

	velocity = _apply_horizontal(Vector3.ZERO, player.settings.walk_speed, delta, velocity, player.settings.idle_stop_damping_multiplier)
	player.velocity = velocity
	player.move_and_slide()
