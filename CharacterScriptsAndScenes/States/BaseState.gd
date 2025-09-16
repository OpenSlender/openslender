class_name BaseState
extends Resource


func enter(_player):
	pass

func update(_player, _delta: float) -> void:
	pass

func physics_update(_player, _delta: float) -> void:
	pass

func handle_input(_player, _input_event: InputEvent) -> void:
	pass

func exit(_player) -> void:
	pass

func get_state_name() -> String:
	var script: Script = get_script()
	if script and script.resource_path != "":
		var n: String = String(script.resource_path.get_file().get_basename())
		if n.ends_with("State"):
			return n.left(n.length() - 5)
		return n
	return "Unknown"
