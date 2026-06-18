extends Node3D

var loaded_zones: Dictionary = {}
var current_zone: String = ""
var is_transitioning: bool = false

var adjacent_zones: Dictionary = {
	"main_building": ["courtyard", "science_wing"],
	"science_wing": ["main_building", "courtyard"],
	"gymnasium": ["main_building", "courtyard"],
	"cafeteria": ["main_building", "courtyard"],
	"courtyard": ["main_building", "science_wing", "gymnasium", "cafeteria", "maintenance"],
	"maintenance": ["courtyard", "basement_lab"],
	"basement_lab": ["maintenance"],
	"exterior": ["courtyard"],
}

const ZONE_PATHS = {
	"main_building": "res://zones/main_building.tscn",
	"science_wing": "res://zones/science_wing.tscn",
	"gymnasium": "res://zones/gymnasium.tscn",
	"cafeteria": "res://zones/cafeteria.tscn",
	"courtyard": "res://zones/courtyard.tscn",
	"maintenance": "res://zones/maintenance.tscn",
	"basement_lab": "res://zones/basement_lab.tscn",
	"exterior": "res://zones/exterior.tscn",
}

signal zone_transition_complete(zone_id: String)

func _ready():
	# Connect zone triggers
	EventBus.zone_entered.connect(_on_zone_entered)

func transition_to_zone(zone_id: String):
	if zone_id == current_zone or is_transitioning:
		return
	is_transitioning = true
	var old_zone = current_zone
	
	EventBus.zone_transition_started.emit(old_zone, zone_id)
	
	current_zone = zone_id
	GameState.current_zone = zone_id
	
	# Load the target zone first
	_load_zone(zone_id)
	
	# Preload adjacent zones
	for adj in adjacent_zones.get(zone_id, []):
		_load_zone(adj)
	
	# Unload zones that are no longer needed
	if old_zone != "" and old_zone not in adjacent_zones.get(zone_id, []):
		_unload_zone(old_zone)
	for z in loaded_zones.keys():
		if z != zone_id and z not in adjacent_zones.get(zone_id, []):
			_unload_zone(z)
	
	is_transitioning = false
	EventBus.zone_transition_complete.emit(zone_id)
	EventBus.zone_entered.emit(zone_id)

func _load_zone(zone_id: String):
	if zone_id in loaded_zones:
		return
	if not ZONE_PATHS.has(zone_id):
		push_warning("Zone path not found for: " + zone_id)
		return
	
	var scene = load(ZONE_PATHS[zone_id])
	if not scene:
		push_error("Failed to load zone scene: " + zone_id)
		return
	
	var instance = scene.instantiate()
	add_child(instance)
	loaded_zones[zone_id] = instance
	EventBus.zone_loaded.emit(zone_id)
	print("Loaded zone: ", zone_id)

func _unload_zone(zone_id: String):
	if zone_id not in loaded_zones:
		return
	loaded_zones[zone_id].queue_free()
	loaded_zones.erase(zone_id)
	EventBus.zone_unloaded.emit(zone_id)
	print("Unloaded zone: ", zone_id)

func _on_zone_entered(zone_id: String):
	if zone_id != current_zone:
		transition_to_zone(zone_id)

func get_current_zone() -> String:
	return current_zone

func is_zone_loaded(zone_id: String) -> bool:
	return zone_id in loaded_zones

func get_loaded_zone_count() -> int:
	return loaded_zones.size()

# Memory management for low-end hardware
func force_unload_all_except(zone_id: String):
	for z in loaded_zones.keys():
		if z != zone_id:
			_unload_zone(z)
