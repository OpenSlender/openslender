extends SpotLight3D

@onready var timer = $Timer
@onready var timer2 = $Timer2
var base_energy = 4.394
var flicker_range := 0.5
var min_energy := 0.05
var max_energy := 4
var flickering_active := false
var flickering_time_left := 0.0
var player: CharacterBody3D = null

func _input(event):
	if player == null or !player.is_local_player:
		return
	if event.is_action_pressed("flashlight"):
		var new_visible_state = not $".".visible
		player.set_flashlight_visible(new_visible_state)
		flickering_active = false
		$".".light_energy = base_energy

func _process(delta):
	if flickering_active:
		flicker(delta)
		flickering_time_left -= delta
		if flickering_time_left <= 0:
			flickering_active = false
			$".".light_energy = base_energy


func flicker(delta):
	$".".light_energy = clamp(light_energy + randf_range(-flicker_range, flicker_range), min_energy, max_energy)

func _ready():
	player = _find_player_ancestor()
	timer.timeout.connect(_on_timer_timeout)
	timer2.timeout.connect(_on_timer2_timeout)
	_set_new_random_time()

func _find_player_ancestor() -> CharacterBody3D:
	var current_node = get_parent()
	while current_node != null:
		if current_node is CharacterBody3D and current_node.has_method("send_transform_to_peers"):
			return current_node
		current_node = current_node.get_parent()
	return null
	
func _on_timer2_timeout():
	_set_new_random_time()
	
func _on_timer_timeout():
	var time_flickering := randf_range(1.0, 20.0)
	flickering_active = true
	flickering_time_left = time_flickering
	timer2.start(time_flickering)
	_set_new_random_time()

func _set_new_random_time():
	var new_time = randf_range(1.0, 5.0)
	
	timer.wait_time = new_time
	timer.start()
