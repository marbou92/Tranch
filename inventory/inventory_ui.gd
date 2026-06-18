extends Control

# Slot scene reference — lazy-loaded. The scene file (inventory_slot.tscn)
# will be created in M2 when we build the inventory UI properly. Until then,
# the UI code compiles but won't render slots.
const SLOT_SCENE_PATH = "res://ui/inventory_slot.tscn"
var inventory: Node
var is_open: bool = false

@onready var grid_container = $MarginContainer/VBoxContainer/GridContainer
@onready var examine_panel = $ExaminePanel
@onready var item_model_viewport = $ExaminePanel/SubViewportContainer/SubViewport


func _ready():
	visible = false
	inventory = get_node_or_null("/root/InventorySystem")
	if inventory:
		inventory.slot_changed.connect(_on_slot_changed)
	EventBus.inventory_opened.connect(_open)
	EventBus.inventory_closed.connect(_close)


func _load_slot_scene() -> PackedScene:
	if not ResourceLoader.exists(SLOT_SCENE_PATH):
		push_warning("Inventory UI: slot scene not found at " + SLOT_SCENE_PATH)
		return null
	return load(SLOT_SCENE_PATH)


func _unhandled_input(event):
	if event.is_action_pressed("toggle_inventory"):
		if is_open:
			_close()
		else:
			_open()


func _open():
	is_open = true
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	EventBus.inventory_opened.emit()
	_refresh_slots()


func _close():
	is_open = false
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	examine_panel.visible = false
	EventBus.inventory_closed.emit()


func _refresh_slots():
	for child in grid_container.get_children():
		child.queue_free()
	for i in range(inventory.MAX_SLOTS if inventory else 8):
		var slot_scene = _load_slot_scene()
		if slot_scene == null:
			return
		var slot = slot_scene.instantiate()
		slot.slot_index = i
		slot.clicked.connect(_on_slot_clicked)
		grid_container.add_child(slot)
		if inventory:
			slot.update_display(inventory.get_slot(i))


func _on_slot_changed(slot_index: int, item: Dictionary):
	var slots = grid_container.get_children()
	if slot_index < slots.size():
		slots[slot_index].update_display(item)


func _on_slot_clicked(slot_index: int, button: int):
	if not inventory:
		return
	if button == MOUSE_BUTTON_LEFT:
		inventory.use_item(slot_index)
	elif button == MOUSE_BUTTON_RIGHT:
		inventory.remove_item(slot_index)


func _on_examine_item(slot_index: int):
	if not inventory:
		return

		# Load 3D model for examination would go here
	var item = inventory.get_slot(slot_index)
	if item["item_id"] == "":
		return

		# Load 3D model for examination would go here
	examine_panel.visible = true
	# Load 3D model for examination would go here
