extends StaticBody3D

@export var item_id: String = ""
@export var interaction_text: String = "E — Interact"
@export var is_pickup: bool = false
@export var is_examinable: bool = true
@export var pickup_category: int = 5  # ItemCategory.STORY
@export var highlight_color: Color = Color(1, 1, 1, 0.3)

var is_highlighted: bool = false


func interact(player: CharacterBody3D):
	if is_pickup and item_id != "":
		_pick_up(player)
	else:
		_custom_interact(player)


func _pick_up(player: CharacterBody3D):
	var inv = get_node_or_null("/root/InventorySystem")
	if inv and inv.try_add_item(item_id, pickup_category as InventorySystem.ItemCategory):
		# Success - remove from world
		queue_free()
	else:
		# Inventory full feedback
		pass


func _custom_interact(_player: CharacterBody3D):
	# Override in specific interactable scripts
	pass


func get_interaction_text() -> String:
	return interaction_text


func set_highlight(enabled: bool):
	is_highlighted = enabled
	# Update outline shader or material
	if has_node("MeshInstance3D"):
		var mesh = $MeshInstance3D
		if enabled:
			mesh.material_overlay = _create_outline_mat()
		else:
			mesh.material_overlay = null


func _create_outline_mat() -> ShaderMaterial:
	var mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/interactable_outline.gdshader")
	return mat
