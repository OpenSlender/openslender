extends Control

@onready var connection_panel: Panel = $ConnectionPanel
@onready var address_input: LineEdit = %AddressInput
@onready var port_input: LineEdit = %PortInput
@onready var connect_button: Button = %ConnectButton
@onready var status_label: Label = %StatusLabel
@onready var player_list_panel: Panel = $PlayerListPanel
@onready var player_list: ItemList = %PlayerList
@onready var client_connection: Node = $ClientConnection

const NetworkConstants = preload("res://networking/shared/NetworkConstants.gd")

func _ready() -> void:
	address_input.text = NetworkConstants.DEFAULT_SERVER_ADDRESS
	port_input.text = str(NetworkConstants.DEFAULT_SERVER_PORT)
	
	connect_button.pressed.connect(_on_connect_button_pressed)
	
	client_connection.connection_succeeded.connect(_on_connection_succeeded)
	client_connection.connection_failed.connect(_on_connection_failed)
	client_connection.server_disconnected.connect(_on_server_disconnected)
	client_connection.player_list_updated.connect(_on_player_list_updated)
	
	_update_ui_state(false)

func _on_connect_button_pressed() -> void:
	if client_connection.connected:
		_disconnect()
	else:
		_connect()

func _connect() -> void:
	var address = address_input.text
	var port = int(port_input.text)
	
	if address.is_empty():
		status_label.text = "Please enter server address"
		return
	
	if port <= 0 or port > 65535:
		status_label.text = "Invalid port number"
		return
	
	status_label.text = "Connecting..."
	connect_button.disabled = true
	client_connection.connect_to_server(address, port)

func _disconnect() -> void:
	client_connection.disconnect_from_server()
	_update_ui_state(false)
	status_label.text = "Disconnected"
	player_list.clear()

func _on_connection_succeeded() -> void:
	_update_ui_state(true)
	status_label.text = "Connected (ID: %d)" % client_connection.get_my_peer_id()

func _on_connection_failed() -> void:
	_update_ui_state(false)
	status_label.text = "Connection failed"

func _on_server_disconnected() -> void:
	_update_ui_state(false)
	status_label.text = "Server disconnected"
	player_list.clear()

func _on_player_list_updated(player_ids: Array) -> void:
	player_list.clear()
	var my_id = client_connection.get_my_peer_id()
	
	for player_id in player_ids:
		var display_text = "Player %d" % player_id
		if player_id == my_id:
			display_text += " (You)"
		player_list.add_item(display_text)

func _update_ui_state(connected: bool) -> void:
	connect_button.disabled = false
	address_input.editable = !connected
	port_input.editable = !connected
	
	if connected:
		connect_button.text = "Disconnect"
	else:
		connect_button.text = "Connect"
