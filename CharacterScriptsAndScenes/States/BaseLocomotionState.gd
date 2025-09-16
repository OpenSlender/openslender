class_name BaseLocomotionState
extends "res://CharacterScriptsAndScenes/States/BaseState.gd"


func _handle_airborne(player, velocity: Vector3, delta: float) -> Dictionary:
	var v := velocity
	if not player.is_on_floor():
		v.y -= StateUtils.get_gravity() * delta
		player.state_machine.change_state(StateNames.States.Falling, player)
		return {"handled": true, "velocity": v}
	return {"handled": false, "velocity": v}

static func _read_input_2d() -> Vector2:
	return Input.get_vector("left", "right", "up", "down")

static func _compute_world_direction(player, input_dir: Vector2) -> Vector3:
	return (player.transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

static func _try_start_jump(player) -> bool:
	if Input.is_action_just_pressed("ui_accept"):
		player.state_machine.change_state(StateNames.States.Jumping, player)
		return true
	return false

static func _try_start_crouch(player) -> bool:
	if Input.is_action_pressed("crouch"):
		player.state_machine.change_state(StateNames.States.Crouching, player)
		return true
	return false

static func _apply_horizontal(direction: Vector3, speed: float, delta: float, velocity: Vector3, damping_multiplier: float = 1.0) -> Vector3:
	var v := velocity
	if direction != Vector3.ZERO:
		v.x = direction.x * speed
		v.z = direction.z * speed
	else:
		v.x = move_toward(v.x, 0.0, speed * delta * damping_multiplier)
		v.z = move_toward(v.z, 0.0, speed * delta * damping_multiplier)
	return v
