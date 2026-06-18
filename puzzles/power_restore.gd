extends PuzzleBase

@export var required_circuit_id: String = "cold_storage"
@export var correct_breaker_position: int = 1

var power_restored: bool = false
var current_breaker_position: int = 0

func set_breaker_position(position: int):
	current_breaker_position = position
	EventBus.play_sfx.emit("res://audio/sfx/breaker_switch.ogg", global_position)

	if current_breaker_position == correct_breaker_position:
		restore_power()

func restore_power():
	if is_solved:
		return
	power_restored = true
	solve()
	EventBus.play_sfx.emit("res://audio/sfx/power_restore.ogg", global_position)
	# Enable lights in the connected area
	_enable_area_lights()

func _enable_area_lights():
	# Find lights in the associated room and turn them on
	var parent_zone = _get_parent_zone()
	if parent_zone and parent_zone.has_node("Rooms/ColdStorage"):
		var cold_storage = parent_zone.get_node("Rooms/ColdStorage")
		for light in cold_storage.find_children("*", "Light3D"):
			light.visible = true
			if light is OmniLight3D:
				light.light_energy = 0.8

func _get_parent_zone() -> Node3D:
	var parent = get_parent()
	while parent:
		if parent.is_in_group("zones"):
			return parent
		parent = parent.get_parent()
	return null
