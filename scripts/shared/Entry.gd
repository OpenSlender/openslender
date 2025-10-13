extends Node

func _ready() -> void:
	var server_mode: bool = false

	var args: PackedStringArray = OS.get_cmdline_args()
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	
	print("Command line args: ", args)
	print("User args: ", user_args)
	
	if "--server" in args or "--server" in user_args:
		server_mode = true

	if OS.has_feature("dedicated_server"):
		server_mode = true

	if DisplayServer.get_name() == "headless":
		server_mode = true

	if server_mode:
		print("Starting in server mode...")
		call_deferred("_change_to_scene", "res://scenes/server.tscn")
	else:
		print("Starting in client mode...")
		call_deferred("_change_to_scene", "res://scenes/client.tscn")

func _change_to_scene(scene_path: String) -> void:
	get_tree().change_scene_to_file(scene_path)
