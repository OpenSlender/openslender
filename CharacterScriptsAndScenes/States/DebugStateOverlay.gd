class_name DebugStateOverlay
extends Control

var _state_label: Label
var _velocity_label: Label
var _position_label: Label
var _fps_label: Label
var _instructions_label: Label

var _player
var _is_visible := false

func _ready() -> void:
	print("DebugStateOverlay: Initializing")
	position = Vector2(10, 10)
	size = Vector2(380, 200)
	modulate = Color(1.0, 1.0, 1.0, 0.5)

	var background := ColorRect.new()
	background.position = Vector2(0, 0)
	background.size = Vector2(280, 200)
	background.color = Color(0.0, 0.0, 0.0, 1.0)
	add_child(background)

	var border := ColorRect.new()
	border.position = Vector2(-2, -2)
	border.size = Vector2(284, 204)
	border.color = Color(0.4, 0.4, 0.4, 1.0)
	add_child(border)
	move_child(border, 0)

	var content_margin := MarginContainer.new()
	content_margin.position = Vector2(0, 0)
	content_margin.size = Vector2(280, 200)
	content_margin.add_theme_constant_override("margin_left", 15)
	content_margin.add_theme_constant_override("margin_top", 15)
	content_margin.add_theme_constant_override("margin_right", 15)
	content_margin.add_theme_constant_override("margin_bottom", 15)
	add_child(content_margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	content_margin.add_child(vbox)

	_state_label = _create_label("State: Unknown")
	vbox.add_child(_state_label)

	_velocity_label = _create_label("Velocity: (0.0, 0.0, 0.0)")
	vbox.add_child(_velocity_label)

	_position_label = _create_label("Position: (0.0, 0.0, 0.0)")
	vbox.add_child(_position_label)

	_fps_label = _create_label("FPS: 0")
	vbox.add_child(_fps_label)

	var sep := HSeparator.new()
	sep.add_theme_color_override("separator", Color(0.5, 0.5, 0.5, 0.5))
	vbox.add_child(sep)

	_instructions_label = _create_label("Press F3 to toggle this overlay", Color(0.7, 0.7, 0.7))
	vbox.add_child(_instructions_label)

	visible = _is_visible
	call_deferred("find_player_reference")

func _create_label(text: String, color: Color = Color.WHITE) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	return label

func find_player_reference() -> void:
	if _player != null and is_instance_valid(_player):
		return
	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]
		if _player != null and is_instance_valid(_player):
			print("DebugStateOverlay: Found player")
			return
	_player = null

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_F3:
		print("DebugStateOverlay: F3 pressed, toggling visibility")
		toggle_visibility()
		get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not _is_visible:
		return
	if _player == null:
		find_player_reference()
	_update_debug_info()

func _update_debug_info() -> void:
	_fps_label.text = "FPS: %s" % Engine.get_frames_per_second()
	if _player == null:
		_state_label.text = "State: Player not found"
		_velocity_label.text = "Velocity: N/A"
		_position_label.text = "Position: N/A"
		return
	var current_state := "Unknown"
	if "state_machine" in _player and _player.state_machine:
		current_state = _player.state_machine.get_current_state_name()
	_state_label.text = "State: %s" % current_state
	var velocity: Vector3 = _player.velocity
	_velocity_label.text = "Velocity: (%.1f, %.1f, %.1f)" % [velocity.x, velocity.y, velocity.z]
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	_velocity_label.text += "\nH-Speed: %.1f | On Floor: %s" % [horizontal_speed, str(_player.is_on_floor())]
	var gpos: Vector3 = _player.global_position
	_position_label.text = "Position: (%.1f, %.1f, %.1f)" % [gpos.x, gpos.y, gpos.z]

func toggle_visibility() -> void:
	_is_visible = not _is_visible
	visible = _is_visible
	print("Debug overlay: %s" % ("VISIBLE" if _is_visible else "HIDDEN"))

func set_player(player) -> void:
	_player = player
	if _player != null:
		print("DebugStateOverlay: Player reference set directly")

func show_state_transition(from_state: String, to_state: String) -> void:
	if _is_visible:
		print("State Transition: %s -> %s" % [from_state, to_state])

func _exit_tree() -> void:
	_player = null
	print("DebugStateOverlay: Cleaned up")
