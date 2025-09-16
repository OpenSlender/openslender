class_name JumpingState
extends "res://CharacterScriptsAndScenes/States/BaseState.gd"
var _initial_speed := 0.0

func enter(player) -> void:
	var velocity: Vector3 = player.velocity
	var current_horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	_initial_speed = current_horizontal_speed
	velocity.y = player.settings.jump_velocity
	player.velocity = velocity

func physics_update(player, delta: float) -> void:
	var velocity: Vector3 = player.velocity
	velocity.y -= StateUtils.get_gravity() * delta

	if Input.is_action_pressed("crouch"):
		player.set_crouch_state(true)
	else:
		player.set_crouch_state(false)

	if velocity.y <= 0.0:
		player.state_machine.change_state(StateNames.States.Falling, player)
		return

	var input_dir := Input.get_vector("left", "right", "up", "down")
	var direction: Vector3 = (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	var target_speed: float = player.settings.run_speed if Input.is_action_pressed("run") else player.settings.walk_speed

	if direction != Vector3.ZERO:
		var desired_max_speed: float = target_speed * player.settings.jump_desired_speed_factor
		var dir: Vector3 = Vector3(direction.x, 0, direction.z)
		var current_horizontal: Vector3 = Vector3(velocity.x, 0, velocity.z)
		var speed_along: float = current_horizontal.dot(dir)
		var needed: float = desired_max_speed - speed_along
		if needed > 0.0:
			var max_delta: float = player.settings.air_control_acceleration * delta
			var accel: float = min(needed, max_delta)
			current_horizontal += dir * accel
		velocity.x = current_horizontal.x
		velocity.z = current_horizontal.z

	player.velocity = velocity
	player.move_and_slide()

	if player.is_on_floor() and velocity.y <= 0.0:
		player.state_machine.change_state(StateNames.States.Landing, player)
		return
