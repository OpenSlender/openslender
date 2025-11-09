extends CharacterBody3D

const PLAYER_GROUP = "player"
const DEBUG_CANVAS_LAYER_NAME = "DebugCanvasLayer"
const DEBUG_CANVAS_LAYER_LAYER = 100

@onready var _collision_shape: CollisionShape3D = $CollisionShape3D
@onready var _mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera: Camera3D = $CameraPivot/Camera3D
@onready var _hud: Control = $CameraPivot/Camera3D/HUD
@onready var _crosshair: Control = $CameraPivot/Camera3D/Crosshair
@onready var _pickup_prompt: Control = $CameraPivot/Camera3D/PickupPrompt
@onready var _flashlight: SpotLight3D = $CameraPivot/Camera3D/SpotLight3D
@export var settings: PlayerSettingsGD
var _pitch := 0.0

var _is_crouching := false
var _normal_camera_height := 0.0
var _crouch_camera_height := -0.3
var _camera_transition_speed := 8.0

var _capsule_shape: CapsuleShape3D
var _normal_capsule_height := 2.0
var _crouch_capsule_height := 2.0

var _capsule_mesh: CapsuleMesh

var state_machine

var _debug_overlay
var _debug_canvas_layer: CanvasLayer

var network_peer_id: int = 0
var is_local_player := true
var remote_peer_ids: Array = []
var _transform_send_timer := 0.0
var _target_remote_transform: Transform3D
var _target_remote_velocity: Vector3 = Vector3.ZERO
var _remote_lerp_speed := 12.0
var _has_remote_target := false
var _target_remote_pitch := 0.0
var _flashlight_visible := true
var _target_remote_flashlight_visible := true

const SERVER_PEER_ID := 1
const TRANSFORM_SEND_INTERVAL := 0.05

func _ready() -> void:
	add_to_group(PLAYER_GROUP)
	
	if settings == null:
		settings = PlayerSettingsGD.new()
	
	_capsule_shape = _collision_shape.shape as CapsuleShape3D
	_normal_capsule_height = _capsule_shape.height
	_crouch_capsule_height = _normal_capsule_height * settings.crouch_height_ratio
	_capsule_mesh = _mesh_instance.mesh as CapsuleMesh
	_crouch_camera_height = settings.crouch_camera_height
	_camera_transition_speed = settings.camera_transition_speed
	_initialize_state_machine()
	_apply_network_state()

func _initialize_state_machine() -> void:
	state_machine = StateMachine.new()
	add_child(state_machine)
	
	state_machine.add_state_auto(IdleState.new())
	state_machine.add_state_auto(WalkingState.new())
	state_machine.add_state_auto(RunningState.new())
	state_machine.add_state_auto(CrouchingState.new())
	state_machine.add_state_auto(JumpingState.new())
	state_machine.add_state_auto(FallingState.new())
	state_machine.add_state_auto(LandingState.new())
	
	state_machine.set_initial_state(StateNames.States.Idle, self)
	state_machine.connect("state_changed", Callable(self, "_on_state_changed"))

func _on_state_changed(from_state: String, to_state: String) -> void:
	if _debug_overlay:
		_debug_overlay.show_state_transition(from_state, to_state)

func _initialize_debug_overlay() -> void:
	_debug_canvas_layer = CanvasLayer.new()
	_debug_canvas_layer.layer = DEBUG_CANVAS_LAYER_LAYER
	_debug_canvas_layer.name = DEBUG_CANVAS_LAYER_NAME
	get_tree().root.call_deferred("add_child", _debug_canvas_layer)
	call_deferred("_create_debug_overlay_control")

func _create_debug_overlay_control() -> void:
	_debug_overlay = DebugStateOverlay.new()
	_debug_canvas_layer.add_child(_debug_overlay)
	_debug_overlay.set_player(self)

func _input(event: InputEvent) -> void:
	if !is_local_player:
		return
	if Input.is_action_just_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		if _debug_overlay:
			_debug_overlay.toggle_visibility()
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x * settings.mouse_sensitivity))
		_pitch -= event.relative.y * settings.mouse_sensitivity
		_pitch = clampf(_pitch, -settings.max_pitch_degrees, settings.max_pitch_degrees)
		if _camera_pivot != null:
			_camera_pivot.rotation_degrees = Vector3(_pitch, 0, 0)
	if state_machine:
		state_machine.handle_input(self, event)

func _physics_process(delta: float) -> void:
	if !is_local_player:
		return
	if state_machine:
		state_machine.physics_update(self, delta)
	_transform_send_timer += delta
	if _transform_send_timer >= TRANSFORM_SEND_INTERVAL:
		_transform_send_timer = 0.0
		send_transform_to_peers()

func get_current_state_info() -> String:
	return "Current State: %s" % (state_machine.get_current_state_name() if state_machine else "None")

func force_state_change(state_name: String) -> void:
	if state_machine:
		state_machine.change_state(state_name, self)

func set_crouch_state(crouching: bool) -> void:
	_is_crouching = crouching
	_update_collision_shape()

func _update_collision_shape() -> void:
	if _capsule_shape != null:
		var old_height := _capsule_shape.height
		var target_height := _crouch_capsule_height if _is_crouching else _normal_capsule_height
		var height_diff := old_height - target_height
		if is_on_floor() and height_diff != 0.0:
			var current_pos := global_position
			current_pos.y -= height_diff * 0.5
			global_position = current_pos
		_capsule_shape.height = target_height
	if _capsule_mesh != null:
		var target_h := _crouch_capsule_height if _is_crouching else _normal_capsule_height
		_capsule_mesh.height = target_h

func _process(delta: float) -> void:
	if is_local_player:
		if state_machine:
			state_machine.update(self, delta)
		_update_camera_height(delta)
	else:
		_update_remote_motion(delta)

func _update_camera_height(delta: float) -> void:
	if _camera_pivot == null:
		return
	var target_y := _crouch_camera_height if _is_crouching else _normal_camera_height
	var current_y := _camera_pivot.position.y
	var new_y := move_toward(current_y, target_y, _camera_transition_speed * delta)
	_camera_pivot.position = Vector3(_camera_pivot.position.x, new_y, _camera_pivot.position.z)

func _exit_tree() -> void:
	# No overlay object yet; safe to ignore
	pass

func set_network_identity(peer_id: int, local_player: bool) -> void:
	network_peer_id = peer_id
	is_local_player = local_player
	if is_inside_tree():
		_apply_network_state()

func set_remote_peer_ids(peer_ids: Array) -> void:
	var filtered: Array = []
	for peer_id in peer_ids:
		if peer_id == network_peer_id or peer_id == SERVER_PEER_ID:
			continue
		if peer_id in filtered:
			continue
		filtered.append(peer_id)
	remote_peer_ids = filtered

func send_transform_to_peers(peer_ids: Array = []) -> void:
	if !is_local_player:
		return
	if peer_ids.is_empty():
		peer_ids = remote_peer_ids
	if peer_ids.is_empty():
		return
	for peer_id in peer_ids:
		if peer_id == network_peer_id or peer_id == SERVER_PEER_ID:
			continue
		rpc_id(peer_id, "_rpc_receive_remote_transform", global_transform, velocity, _pitch, network_peer_id)

func set_flashlight_visible(visible_state: bool) -> void:
	if _flashlight_visible == visible_state:
		return

	_flashlight_visible = visible_state
	if _flashlight:
		_flashlight.visible = visible_state

	if is_local_player:
		send_flashlight_state_to_peers()

func send_flashlight_state_to_peers(peer_ids: Array = []) -> void:
	if !is_local_player:
		return
	if peer_ids.is_empty():
		peer_ids = remote_peer_ids
	if peer_ids.is_empty():
		return
	for peer_id in peer_ids:
		if peer_id == network_peer_id or peer_id == SERVER_PEER_ID:
			continue
		rpc_id(peer_id, "_rpc_receive_flashlight_state", _flashlight_visible, network_peer_id)

func release_input_focus() -> void:
	if is_local_player:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		_target_remote_transform = global_transform
		if _camera_pivot:
			_target_remote_pitch = _camera_pivot.rotation_degrees.x

func _apply_network_state() -> void:
	if is_local_player:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		set_process_input(true)
		_apply_local_visual_state()
		if _debug_overlay == null:
			call_deferred("_initialize_debug_overlay")
	else:
		set_process_input(false)
		_apply_remote_visual_state()
		_target_remote_transform = global_transform
		_has_remote_target = true
		if _camera_pivot:
			_target_remote_pitch = _camera_pivot.rotation_degrees.x
			_pitch = _target_remote_pitch
		_transform_send_timer = 0.0

func _apply_local_visual_state() -> void:
	if _camera:
		_camera.current = true
	if _hud:
		_hud.show()
	if _crosshair:
		_crosshair.show()
	if _pickup_prompt:
		_pickup_prompt.hide()

func _apply_remote_visual_state() -> void:
	if _camera:
		_camera.current = false
	if _camera_pivot:
		_camera_pivot.rotation_degrees = Vector3(_target_remote_pitch, 0, 0)
	if _hud:
		_hud.hide()
	if _crosshair:
		_crosshair.hide()
	if _pickup_prompt:
		_pickup_prompt.hide()
	_target_remote_transform = global_transform
	_has_remote_target = true
	if _camera_pivot:
		_target_remote_pitch = _camera_pivot.rotation_degrees.x
		_pitch = _target_remote_pitch
	_target_remote_flashlight_visible = _flashlight_visible
	if _flashlight:
		_flashlight.visible = _flashlight_visible

@rpc("any_peer", "call_local", "unreliable")
func _rpc_receive_remote_transform(remote_transform: Transform3D, remote_velocity: Vector3, remote_pitch: float, claimed_sender_id: int) -> void:
	if is_local_player:
		return

	# Security: Verify the RPC sender matches the claimed sender ID
	var actual_sender_id = multiplayer.get_remote_sender_id()
	if actual_sender_id != claimed_sender_id:
		push_warning("[Player] RPC impersonation attempt: actual sender %d claimed to be %d" % [actual_sender_id, claimed_sender_id])
		return

	_target_remote_transform = remote_transform
	_target_remote_velocity = remote_velocity
	_target_remote_pitch = remote_pitch
	_has_remote_target = true

@rpc("any_peer", "call_local", "reliable")
func _rpc_receive_flashlight_state(flashlight_visible: bool, claimed_sender_id: int) -> void:
	if is_local_player:
		return

	# Security: Verify the RPC sender matches the claimed sender ID
	var actual_sender_id = multiplayer.get_remote_sender_id()
	if actual_sender_id != claimed_sender_id:
		push_warning("[Player] RPC impersonation attempt: actual sender %d claimed to be %d" % [actual_sender_id, claimed_sender_id])
		return

	_target_remote_flashlight_visible = flashlight_visible
	if _flashlight:
		_flashlight.visible = flashlight_visible

func _update_remote_motion(delta: float) -> void:
	if !_has_remote_target:
		return
	var current_transform := global_transform
	var position := current_transform.origin
	var target_position := _target_remote_transform.origin
	var factor := clampf(_remote_lerp_speed * delta, 0.0, 1.0)
	var new_position := position.lerp(target_position, factor)
	current_transform.origin = new_position
	var current_rot := current_transform.basis.orthonormalized().get_rotation_quaternion()
	var target_rot := _target_remote_transform.basis.orthonormalized().get_rotation_quaternion()
	var blended_rot := current_rot.slerp(target_rot, factor)
	current_transform.basis = Basis(blended_rot)

	global_transform = current_transform
	velocity = _target_remote_velocity
	if _camera_pivot:
		_pitch = lerp(_pitch, _target_remote_pitch, factor)
		_camera_pivot.rotation_degrees = Vector3(_pitch, 0, 0)
