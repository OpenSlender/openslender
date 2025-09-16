class_name WalkingState
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
	if _try_start_jump(player): return
	if _try_start_crouch(player): return

	if Input.is_action_pressed("run"):
		player.state_machine.change_state(StateNames.States.Running, player)
		return

	if input_dir.length_squared() < player.settings.input_threshold_squared:
		player.state_machine.change_state(StateNames.States.Idle, player)
		return

	var direction := _compute_world_direction(player, input_dir)
	velocity = _apply_horizontal(direction, player.settings.walk_speed, delta, velocity)
	player.velocity = velocity
	player.move_and_slide()
