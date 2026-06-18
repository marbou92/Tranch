extends Node3D

@export var zone_id: String = ""
@export var zone_name: String = ""
@export var threat_level: int = 0  # 0-5
@export var has_safe_room: bool = false
@export var ambient_color: Color = Color(0.03, 0.03, 0.05)
@export var fog_enabled: bool = true
@export var fog_density: float = 0.02

var is_loaded: bool = false
var puzzle_states: Dictionary = {}

signal zone_ready(zone_id: String)
signal zone_cleanup(zone_id: String)

func _ready():
	add_to_group("zones")
	is_loaded = true
	_setup_zone()
	zone_ready.emit(zone_id)

func _setup_zone():
	# Configure environment
	var env = get_world_3d().environment if get_world_3d() else null
	if env:
		env.ambient_light_color = ambient_color
		env.fog_enabled = fog_enabled
		env.fog_density = fog_density
	
	# Connect zone triggers
	for trigger in _get_zone_triggers():
		if trigger is Area3D:
			trigger.body_entered.connect(_on_trigger_body_entered.bind(trigger))

func _get_zone_triggers() -> Array:
	var triggers = []
	if has_node("ZoneTriggers"):
		for child in $ZoneTriggers.get_children():
			triggers.append(child)
	return triggers

func _on_trigger_body_entered(body: Node3D, trigger: Area3D):
	if not body.is_in_group("player"):
		return
	
	var trigger_name = trigger.name.to_lower()
	var target_zone = ""
	
	if "courtyard" in trigger_name:
		target_zone = "courtyard"
	elif "main_building" in trigger_name:
		target_zone = "main_building"
	elif "science" in trigger_name:
		target_zone = "science_wing"
	elif "gymnasium" in trigger_name:
		target_zone = "gymnasium"
	elif "cafeteria" in trigger_name:
		target_zone = "cafeteria"
	elif "maintenance" in trigger_name:
		target_zone = "maintenance"
	elif "basement" in trigger_name:
		target_zone = "basement_lab"
	elif "exterior" in trigger_name:
		target_zone = "exterior"
	
	if target_zone != "":
		EventBus.zone_entered.emit(target_zone)

func get_patrol_waypoints() -> Array:
	var waypoints = []
	if has_node("PatrolWaypoints"):
		for wp in $PatrolWaypoints.get_children():
			if wp is Marker3D:
				waypoints.append(wp)
	return waypoints

func get_safe_room_positions() -> Array:
	var positions = []
	if has_node("SafeRooms"):
		for marker in $SafeRooms.get_children():
			if marker is Marker3D:
				positions.append(marker.global_position)
	return positions

func get_key_item_markers() -> Array:
	var markers = []
	if has_node("KeyItemLocations"):
		for marker in $KeyItemLocations.get_children():
			if marker is Marker3D:
				markers.append(marker)
	return markers

func set_puzzle_state(puzzle_id: String, state: Variant):
	puzzle_states[puzzle_id] = state

func get_puzzle_state(puzzle_id: String) -> Variant:
	return puzzle_states.get(puzzle_id, null)

func cleanup():
	zone_cleanup.emit(zone_id)
	is_loaded = false
