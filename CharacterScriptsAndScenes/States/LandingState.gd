class_name LandingState
extends "res://CharacterScriptsAndScenes/States/BaseState.gd"


var _landing_timer := 0.0

func enter(player) -> void:
	_landing_timer = 0.0
	var velocity: Vector3 = player.velocity
	if velocity.y < 0.0:
		velocity.y = 0.0
		player.velocity = velocity

func physics_update(player, delta: float) -> void:
	_landing_timer += delta
	var velocity: Vector3 = player.velocity
	if not player.is_on_floor():
		velocity.y -= StateUtils.get_gravity() * delta
		player.state_machine.change_state(StateNames.States.Falling, player)
		return

	var input_dir := Input.get_vector("left", "right", "up", "down")
	if Input.is_action_just_pressed("ui_accept"):
		player.state_machine.change_state(StateNames.States.Jumping, player)
		return

	if _landing_timer >= player.settings.landing_duration:
		if Input.is_action_pressed("crouch"):
			player.state_machine.change_state(StateNames.States.Crouching, player)
			return
		if input_dir.length_squared() > player.settings.input_threshold_squared:
			player.state_machine.change_state(StateNames.States.Walking, player)
			return
		else:
			player.state_machine.change_state(StateNames.States.Idle, player)
			return

	velocity.x = move_toward(velocity.x, 0.0, player.settings.walk_speed * delta * player.settings.landing_stop_damping_multiplier)
	velocity.z = move_toward(velocity.z, 0.0, player.settings.walk_speed * delta * player.settings.landing_stop_damping_multiplier)
	player.velocity = velocity
	player.move_and_slide()

func exit(_player) -> void:
	_landing_timer = 0.0
