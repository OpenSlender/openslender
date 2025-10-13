extends SpotLight3D

@onready var timer: Timer = $Timer
@onready var timer2: Timer = $Timer2
var base_energy: float = 4.394
var flicker_range := 0.5
var min_energy := 0.05
var max_energy := 4
var flickering_active := false
var flickering_time_left := 0.0

var _player: Node = null

func _input(event) -> void:
	if _player == null:
		return
	if not _player.is_local:
		return
	if event.is_action_pressed("flashlight"):
		$".".visible = not $".".visible
		flickering_active = false
		$".".light_energy = base_energy

func _process(delta):
	if flickering_active:
		flicker(delta)
		flickering_time_left -= delta
		if flickering_time_left <= 0:
			flickering_active = false
			$".".light_energy = base_energy


func flicker(_delta):
	$".".light_energy = clamp(light_energy + randf_range(-flicker_range, flicker_range), min_energy, max_energy)

func _ready():
	var p := get_parent()
	if p: p = p.get_parent()
	if p: p = p.get_parent()
	_player = p
	
	timer.timeout.connect(_on_timer_timeout)
	timer2.timeout.connect(_on_timer2_timeout)
	_set_new_random_time()
	
func _on_timer2_timeout():
	_set_new_random_time()
	
func _on_timer_timeout():
	var time_flickering := randf_range(1.0, 20.0)
	flickering_active = true
	flickering_time_left = time_flickering
	timer2.start(time_flickering)
	_set_new_random_time()

func _set_new_random_time():
	var new_time: float = randf_range(1.0, 5.0)
	
	timer.wait_time = new_time
	timer.start()
