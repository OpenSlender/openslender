extends Node

@onready var server: Node = $DedicatedServer

func _ready() -> void:
	_parse_arguments()

func _parse_arguments() -> void:
	var arguments = OS.get_cmdline_user_args()
	var is_dedicated_server = false
	var port = 7777
	
	for arg in arguments:
		if arg == "--server" or arg == "--dedicated-server":
			is_dedicated_server = true
		elif arg.begins_with("--port="):
			port = int(arg.split("=")[1])
	
	if is_dedicated_server:
		print("Starting dedicated server mode...")
		if server.start_server(port):
			print("Dedicated server is running. Press Ctrl+C to stop.")
		else:
			print("Failed to start dedicated server")
			get_tree().quit()
	else:
		print("Not running as dedicated server. Use --server to start in dedicated server mode.")
		print("Example: godot --headless networking/server/server.tscn -- --server --port=7777")
		get_tree().quit()

