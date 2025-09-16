class_name Collectible
extends Area3D

@export var one_shot: bool = true
@export var mesh_node_path: NodePath

var _collected := false

var _mesh_instance: MeshInstance3D
var _outline_instance: MeshInstance3D

func _enter_tree() -> void:
	add_to_group("collectible")

func _ready() -> void:
	_mesh_instance = get_node_or_null(mesh_node_path) as MeshInstance3D
	if _mesh_instance == null:
		_mesh_instance = get_node_or_null("MeshInstance3D") as MeshInstance3D

	_create_outline_if_missing()

func _create_outline_if_missing() -> void:
	if _outline_instance != null or _mesh_instance == null or _mesh_instance.mesh == null:
		return

	_outline_instance = MeshInstance3D.new()
	_outline_instance.mesh = _mesh_instance.mesh

	var outline_material := StandardMaterial3D.new()
	outline_material.albedo_color = Color.WHITE
	outline_material.emission_enabled = true
	outline_material.emission = Color.WHITE
	outline_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	outline_material.cull_mode = BaseMaterial3D.CULL_FRONT

	_outline_instance.material_override = outline_material
	_outline_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_outline_instance.scale = Vector3(1.03, 1.03, 1.03)
	_outline_instance.visible = false
	add_child(_outline_instance)

func set_highlighted(highlighted: bool) -> void:
	if not is_instance_valid(self):
		return
	if _outline_instance == null:
		_create_outline_if_missing()
	if _outline_instance != null:
		_outline_instance.visible = highlighted

func try_pickup() -> void:
	if _collected:
		return

	_collected = true
	if Engine.has_singleton("GameManager") or typeof(GameManager) != TYPE_NIL:
		GameManager.collect_collectible()

	set_highlighted(false)
	visible = false
	monitoring = false
	if one_shot:
		queue_free()
