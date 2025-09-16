extends RayCast3D

@export var Ray: RayCast3D
@export var PromptLabelPath: NodePath

var _promptLabel: Label
var _currentHighlighted

func _ready() -> void:
	if Ray == null:
		Ray = self

	_promptLabel = get_node_or_null(PromptLabelPath) as Label

	if _promptLabel != null:
		_promptLabel.visible = false

func _process(_delta: float) -> void:
	var collectible = null

	if Ray != null and Ray.is_colliding():
		var collider = Ray.get_collider()
		if collider is Collectible:
			collectible = collider as Collectible
		elif collider is Node:
			var node := collider as Node
			if node.get_parent() is Collectible:
				collectible = node.get_parent() as Collectible

	if _currentHighlighted != collectible:
		if _currentHighlighted != null:
			_currentHighlighted.set_highlighted(false)
		_currentHighlighted = collectible
		if _currentHighlighted != null:
			_currentHighlighted.set_highlighted(true)

	if _promptLabel != null:
		_promptLabel.visible = collectible != null

	if collectible != null and Input.is_action_just_pressed("interact"):
		collectible.try_pickup()
		if _currentHighlighted == collectible:
			_currentHighlighted = null
		if _promptLabel != null:
			_promptLabel.visible = false
