# GUT unit test — inventory stacking rules per GDD §4.4
extends GutTest


func before_each():
	# Reset all 8 slots to empty
	for i in range(InventorySystem.MAX_SLOTS):
		InventorySystem.slots[i] = InventorySystem._empty_slot()


func test_inventory_has_8_slots():
	assert_eq(InventorySystem.MAX_SLOTS, 8, "GDD §4.4: 'Players carry a maximum of 8 slots'")


func test_add_item_fills_empty_slot():
	var ok: bool = InventorySystem.try_add_item("battery_01", InventorySystem.ItemCategory.POWER)
	assert_true(ok, "Adding to empty inventory must succeed")
	assert_eq(InventorySystem.slots[0].item_id, "battery_01")


func test_battery_stacks_to_4_max():
	# GDD §4.4: Power — Flashlight battery — stack=yes — max=4
	for i in range(4):
		var ok: bool = InventorySystem.try_add_item(
			"battery_01", InventorySystem.ItemCategory.POWER
		)
		assert_true(ok, "Battery %d/4 should stack" % (i + 1))
	# 5th battery must go into a NEW slot (not refused, just doesn't stack)
	var ok: bool = InventorySystem.try_add_item("battery_01", InventorySystem.ItemCategory.POWER)
	assert_true(ok, "5th battery must spill into slot 2, not be refused")
	assert_eq(InventorySystem.slots[0].count, 4, "Slot 0 must hold 4 stacked batteries")
	assert_eq(InventorySystem.slots[1].item_id, "battery_01", "Slot 1 must hold the 5th battery")


func test_key_fragments_do_not_stack():
	# GDD §4.4: Keys — stack=no — max=1
	InventorySystem.try_add_item("key_frag_1", InventorySystem.ItemCategory.KEY)
	InventorySystem.try_add_item("key_frag_2", InventorySystem.ItemCategory.KEY)
	InventorySystem.try_add_item("key_frag_3", InventorySystem.ItemCategory.KEY)
	InventorySystem.try_add_item("key_frag_4", InventorySystem.ItemCategory.KEY)
	# Each fragment should be in its own slot
	for i in range(4):
		assert_ne(
			InventorySystem.slots[i].item_id, "", "Key fragment %d must occupy its own slot" % i
		)
		assert_eq(InventorySystem.slots[i].count, 1, "Non-stackable item count must be 1")


func test_full_inventory_refusesNewItem():
	# Fill all 8 slots with non-stackable key items
	for i in range(8):
		InventorySystem.try_add_item("key_%d" % i, InventorySystem.ItemCategory.KEY)
	# 9th should fail
	var ok: bool = InventorySystem.try_add_item("key_extra", InventorySystem.ItemCategory.KEY)
	assert_false(ok, "Inventory must refuse items when all 8 slots are full of non-stackables")


func test_remove_item_clears_slot():
	InventorySystem.try_add_item("battery_01", InventorySystem.ItemCategory.POWER)
	var removed: Dictionary = InventorySystem.remove_item(0)
	assert_eq(removed.item_id, "battery_01", "remove_item should return the removed item")
	assert_eq(InventorySystem.slots[0].item_id, "", "Slot must be empty after remove")


func test_has_item_and_get_item_count():
	InventorySystem.try_add_item("battery_01", InventorySystem.ItemCategory.POWER)
	InventorySystem.try_add_item("battery_01", InventorySystem.ItemCategory.POWER)
	InventorySystem.try_add_item("battery_01", InventorySystem.ItemCategory.POWER)
	assert_true(InventorySystem.has_item("battery_01"))
	assert_eq(InventorySystem.get_item_count("battery_01"), 3)
	assert_false(InventorySystem.has_item("battery_99"))
	assert_eq(InventorySystem.get_item_count("battery_99"), 0)
