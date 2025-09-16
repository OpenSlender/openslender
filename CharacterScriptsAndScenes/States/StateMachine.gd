class_name StateMachine
extends Node


signal state_changed(from_state: String, to_state: String)

var _current_state
var _previous_state
var _states := {}
var debug_logging := false

func _ready() -> void:
	_states = {}

func add_state(state_name: String, state) -> void:
	_states[state_name] = state

func add_state_auto(state) -> void:
	if state == null:
		push_error("Attempted to add a null state to the state machine")
		return
	var state_name: String = state.get_state_name()
	if state_name.strip_edges() == "":
		push_error("Attempted to add a state with an empty name")
		return
	_states[state_name] = state

func change_state(state_name, player) -> void:
	var state_string: String
	if typeof(state_name) == TYPE_INT:
		state_string = StateNames.States.keys()[state_name]
	else:
		state_string = str(state_name)
	_try_change_state(state_string, player)

func _try_change_state(state_name: String, player) -> bool:
	if not _states.has(state_name):
		push_error("State '%s' not found in state machine" % state_name)
		return false
	if _current_state != null and _current_state.get_state_name() == state_name:
		return false
	var previous_name: String = _current_state.get_state_name() if _current_state != null else "None"
	if _current_state != null:
		_current_state.exit(player)
	_previous_state = _current_state
	_current_state = _states[state_name]
	_current_state.enter(player)
	if debug_logging:
		print("State change: %s -> %s" % [previous_name, state_name])
	emit_signal("state_changed", previous_name, state_name)
	return true

func set_initial_state(state_name, player) -> void:
	var state_string: String
	if typeof(state_name) == TYPE_INT:
		state_string = StateNames.States.keys()[state_name]
	else:
		state_string = str(state_name)
	if not _states.has(state_string):
		push_error("Initial state '%s' not found in state machine" % state_string)
		return
	_previous_state = null
	_current_state = _states[state_string]
	_current_state.enter(player)
	print("Initial state set to: %s" % state_string)

func update(player, delta: float) -> void:
	if _current_state:
		_current_state.update(player, delta)

func physics_update(player, delta: float) -> void:
	if _current_state:
		_current_state.physics_update(player, delta)

func handle_input(player, input_event: InputEvent) -> void:
	if _current_state:
		_current_state.handle_input(player, input_event)

func get_available_states() -> PackedStringArray:
	return PackedStringArray(_states.keys())

func has_state(state_name: String) -> bool:
	return _states.has(state_name)

func is_in_state(state_name: String) -> bool:
	return _current_state != null and _current_state.get_state_name() == state_name

func get_current_state_name() -> String:
	return _current_state.get_state_name() if _current_state != null else "None"

func get_previous_state_name() -> String:
	return _previous_state.get_state_name() if _previous_state != null else "None"
