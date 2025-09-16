extends Control

@export var color_: Color = Color.WHITE
@export var thickness: float = 2.0
@export var border_thickness: float = 1.0
@export var border_color: Color = Color.BLACK

func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0
	offset_left = 0.0
	offset_top = 0.0
	offset_right = 0.0
	offset_bottom = 0.0
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	queue_redraw()

func _draw() -> void:
	var center := get_rect().size / 2.0
	draw_circle(center, thickness + border_thickness, border_color)
	draw_circle(center, thickness * 0.75, color_)

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
