@tool
class_name PlayerSettingsGD
extends Resource

@export var walk_speed: float = 5.0
@export var run_speed: float = 8.0
@export var crouch_speed: float = 2.5
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.25

@export_range(-90.0, 90.0, 1.0) var max_pitch_degrees: float = 80.0
@export_range(0.0, 1.0, 0.01) var crouch_height_ratio: float = 0.7
@export var crouch_camera_height: float = -0.3
@export var camera_transition_speed: float = 8.0
@export_range(0.0, 1.0, 0.01) var input_threshold_squared: float = 0.1
@export var idle_stop_damping_multiplier: float = 5.0
@export var crouch_stop_damping_multiplier: float = 5.0
@export var landing_stop_damping_multiplier: float = 3.0

@export var jump_no_input_damping_factor: float = 0.5
@export var fall_no_input_damping_factor: float = 0.3

@export var jump_desired_speed_factor: float = 0.7
@export var fall_desired_speed_factor: float = 0.6
@export var air_control_acceleration: float = 10.0
@export var air_speed_lerp_rate: float = 2.0
@export var landing_duration: float = 0.1
