class_name CrouchingState
extends "res://CharacterScriptsAndScenes/States/BaseLocomotionState.gd"

func enter(player) -> void:
	player.set_crouch_state(true)

func physics_update(player, delta: float) -> void:
	var velocity: Vector3 = player.velocity
	var res := _handle_airborne(player, velocity, delta)
	velocity = res.velocity
	if res.handled:
		player.velocity = velocity
		player.move_and_slide()
		return

	if _try_start_jump(player):
		return

	var input_dir := _read_input_2d()
	if not Input.is_action_pressed("crouch"):
		if input_dir.length_squared() > player.settings.input_threshold_squared:
			player.state_machine.change_state(StateNames.States.Walking, player)
			return
		else:
			player.state_machine.change_state(StateNames.States.Idle, player)
			return

	if input_dir.length_squared() < player.settings.input_threshold_squared:
		velocity = _apply_horizontal(Vector3.ZERO, player.settings.walk_speed, delta, velocity, player.settings.crouch_stop_damping_multiplier)
	else:
		var direction := _compute_world_direction(player, input_dir)
		velocity = _apply_horizontal(direction, player.settings.crouch_speed, delta, velocity)

	player.velocity = velocity
	player.move_and_slide()

func exit(player) -> void:
	player.set_crouch_state(false)
