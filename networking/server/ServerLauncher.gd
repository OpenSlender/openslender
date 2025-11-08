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
			var parts = arg.split("=")
			if parts.size() < 2 or parts[1].is_empty():
				push_error("Error: --port requires a value")
				get_tree().quit(1)
				return

			var port_str = parts[1]
			if not port_str.is_valid_int():
				push_error("Error: Port must be a positive integer (got: %s)" % port_str)
				get_tree().quit(1)
				return

			var parsed_port = int(port_str)
			if parsed_port < 1 or parsed_port > 65535:
				push_error("Error: Port must be between 1 and 65535 (got: %d)" % parsed_port)
				get_tree().quit(1)
				return

			port = parsed_port
	
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

