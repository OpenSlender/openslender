extends CharacterBody3D

const PLAYER_GROUP: String = "player"
const DEBUG_CANVAS_LAYER_NAME: String = "DebugCanvasLayer"
const DEBUG_CANVAS_LAYER_LAYER: int = 100

@onready var _collision_shape: CollisionShape3D = $CollisionShape3D
@onready var _mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var _camera_pivot: Node3D = $CameraPivot
@export var settings: PlayerSettings
@export var is_local: bool = true
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

func _ready() -> void:
	add_to_group(PLAYER_GROUP)
	
	if settings == null:
		settings = PlayerSettings.new()
	
	_capsule_shape = _collision_shape.shape as CapsuleShape3D
	_normal_capsule_height = _capsule_shape.height
	_crouch_capsule_height = _normal_capsule_height * settings.crouch_height_ratio
	_capsule_mesh = _mesh_instance.mesh as CapsuleMesh
	_crouch_camera_height = settings.crouch_camera_height
	_camera_transition_speed = settings.camera_transition_speed
	
	if is_local:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		_initialize_state_machine()
		call_deferred("_initialize_debug_overlay")
	else:
		set_process(false)
		set_physics_process(false)
		set_process_input(false)

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
	if not is_local:
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
	if state_machine:
		state_machine.physics_update(self, delta)

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
	if state_machine:
		state_machine.update(self, delta)
	_update_camera_height(delta)

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
