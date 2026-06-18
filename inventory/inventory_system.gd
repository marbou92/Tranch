extends Node

const MAX_SLOTS = 8

enum ItemCategory { POWER, HEALTH, KEY, TOOL, STORY, CONSUMABLE }

var slots: Array = []
signal slot_changed(slot_index: int, item: Dictionary)
signal inventory_full

func _ready():
	slots.resize(MAX_SLOTS)
	for i in range(MAX_SLOTS):
		slots[i] = _empty_slot()

func _empty_slot() -> Dictionary:
	return {"item_id": "", "category": -1, "count": 0, "data": {}}

func try_add_item(item_id: String, category: ItemCategory, data: Dictionary = {}) -> bool:
	# Check if stackable
	var stack_info = _get_stack_info(category)
	if stack_info.can_stack:
		# Find existing slot with same item
		for i in range(MAX_SLOTS):
			if slots[i]["item_id"] == item_id and slots[i]["count"] < stack_info.max_count:
				slots[i]["count"] += 1
				slot_changed.emit(i, slots[i])
				EventBus.item_picked_up.emit(item_id, i)
				return true
	
	# Find empty slot
	for i in range(MAX_SLOTS):
		if slots[i]["item_id"] == "":
			slots[i] = {
				"item_id": item_id,
				"category": category,
				"count": 1,
				"data": data
			}
			slot_changed.emit(i, slots[i])
			EventBus.item_picked_up.emit(item_id, i)
			return true
	
	inventory_full.emit()
	return false

func remove_item(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return {}
	var item = slots[slot_index].duplicate()
	EventBus.item_dropped.emit(item["item_id"], slot_index)
	slots[slot_index] = _empty_slot()
	slot_changed.emit(slot_index, slots[slot_index])
	return item

func use_item(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= MAX_SLOTS:
		return false
	var item = slots[slot_index]
	if item["item_id"] == "":
		return false
	
	EventBus.item_used.emit(item["item_id"], slot_index)
	
	# Handle consumable usage
	var cat = item["category"] as ItemCategory
	match cat:
		ItemCategory.POWER:
			_use_battery(item)
		ItemCategory.HEALTH:
			_use_health_item(item)
		ItemCategory.CONSUMABLE:
			_use_consumable(item)
	
	# Decrement count for consumables
	if cat in [ItemCategory.POWER, ItemCategory.HEALTH, ItemCategory.CONSUMABLE]:
		item["count"] -= 1
		if item["count"] <= 0:
			slots[slot_index] = _empty_slot()
		slot_changed.emit(slot_index, slots[slot_index])
	
	return true

func _use_battery(item: Dictionary):
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.add_battery(35.0)

func _use_health_item(item: Dictionary):
	var player = get_tree().get_first_node_in_group("player")
	if player and item["item_id"] == "painkiller":
		player.restore_sanity(25.0)
	elif player and item["item_id"] == "bandage":
		player.restore_sanity(15.0)

func _use_consumable(item: Dictionary):
	# Distraction stone - handled via event
	EventBus.play_sfx.emit("res://audio/sfx/stone_throw.ogg", Vector3.ZERO)

func get_slot(index: int) -> Dictionary:
	if index < 0 or index >= MAX_SLOTS:
		return {}
	return slots[index]

func has_item(item_id: String) -> bool:
	for slot in slots:
		if slot["item_id"] == item_id:
			return true
	return false

func get_item_count(item_id: String) -> int:
	var count = 0
	for slot in slots:
		if slot["item_id"] == item_id:
			count += slot["count"]
	return count

func _get_stack_info(category: ItemCategory) -> Dictionary:
	match category:
		ItemCategory.POWER:
			return {"can_stack": true, "max_count": 4}
		ItemCategory.HEALTH:
			return {"can_stack": true, "max_count": 3}
		ItemCategory.KEY:
			return {"can_stack": false, "max_count": 1}
		ItemCategory.TOOL:
			return {"can_stack": false, "max_count": 1}
		ItemCategory.STORY:
			return {"can_stack": false, "max_count": 1}
		ItemCategory.CONSUMABLE:
			return {"can_stack": true, "max_count": 3}
		_:
			return {"can_stack": false, "max_count": 1}

func get_save_data() -> Array:
	return slots.duplicate(true)

func load_save_data(data: Array):
	slots = data
	for i in range(min(slots.size(), MAX_SLOTS)):
		slot_changed.emit(i, slots[i])
