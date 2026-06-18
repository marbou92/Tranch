extends Node

const SAVE_DIR = "user://saves/"
const MAX_SLOTS = 3
const MOBILE_SLOT = 0

var _is_saving: bool = false

func _ready():
	DirAccess.make_dir_recursive_absolute(SAVE_DIR)

func save_game(slot: int = 0) -> bool:
	if GameState.permadeath_enabled:
		push_warning("Cannot save in permadeath mode")
		return false
	if GameState.is_mobile and slot != MOBILE_SLOT:
		slot = MOBILE_SLOT
	
	_is_saving = true
	
	var save_data = {
		"version": ProjectSettings.get_setting("application/config/version"),
		"timestamp": Time.get_datetime_string_from_system(),
		"play_time": GameState.play_time,
		"current_zone": GameState.current_zone,
		"death_count": GameState.death_count,
		"lore_collected": GameState.lore_collected,
		"puzzles_solved": GameState.puzzles_solved,
		"key_fragments": GameState.key_fragments,
		"endings_seen": GameState.endings_seen,
		"permadeath": GameState.permadeath_enabled,
		"player": _save_player(),
		"inventory": _save_inventory(),
		"sanity": _save_sanity(),
		"enemies": _save_enemies(),
		"zones": _save_zones(),
	}
	
	var file_path = SAVE_DIR + "save_%d.json" % slot
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		_is_saving = false
		return false
	
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	_is_saving = false
	
	EventBus.game_saved.emit(slot)
	return true

func load_game(slot: int = 0) -> bool:
	var file_path = SAVE_DIR + "save_%d.json" % slot
	if not FileAccess.file_exists(file_path):
		return false
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return false
	
	var json = JSON.new()
	var err = json.parse(file.get_as_text())
	file.close()
	if err != OK:
		return false
	
	var save_data = json.data
	
	# Restore game state
	GameState.play_time = save_data.get("play_time", 0.0)
	GameState.current_zone = save_data.get("current_zone", "")
	GameState.death_count = save_data.get("death_count", 0)
	GameState.lore_collected = save_data.get("lore_collected", [])
	GameState.puzzles_solved = save_data.get("puzzles_solved", [])
	GameState.key_fragments = save_data.get("key_fragments", 0)
	GameState.endings_seen = save_data.get("endings_seen", [])
	GameState.permadeath_enabled = save_data.get("permadeath", false)
	
	# Restore subsystems
	_load_player(save_data.get("player", {}))
	_load_inventory(save_data.get("inventory", []))
	_load_sanity(save_data.get("sanity", {}))
	_load_enemies(save_data.get("enemies", {}))
	
	GameState.current_phase = GameState.GamePhase.PLAYING
	EventBus.game_loaded.emit(slot)
	return true

func has_save(slot: int = 0) -> bool:
	return FileAccess.file_exists(SAVE_DIR + "save_%d.json" % slot)

func delete_save(slot: int = 0) -> bool:
	var file_path = SAVE_DIR + "save_%d.json" % slot
	if FileAccess.file_exists(file_path):
		DirAccess.remove_absolute(file_path)
		return true
	return false

func auto_save():
	if GameState.is_mobile:
		save_game(MOBILE_SLOT)

func _save_player() -> Dictionary:
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return {}
	return {
		"position": {
			"x": player.global_position.x,
			"y": player.global_position.y,
			"z": player.global_position.z
		},
		"rotation_y": player.rotation.y,
		"flashlight_on": player.flashlight_on,
		"flashlight_battery": player.flashlight_bat,
		"is_crouching": player.is_crouching,
	}

func _save_inventory() -> Array:
	var inv = get_node_or_null("/root/InventorySystem")
	if inv:
		return inv.get_save_data()
	return []

func _save_sanity() -> Dictionary:
	return {
		"sanity": SanitySystem.sanity,
		"is_in_safe_room": SanitySystem.is_in_safe_room,
	}

func _save_enemies() -> Dictionary:
	var enemies = {}
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var id = enemy.name
		enemies[id] = {
			"position": {
				"x": enemy.global_position.x,
				"y": enemy.global_position.y,
				"z": enemy.global_position.z
			},
			"state": enemy.state if "state" in enemy else 0,
		}
	return enemies

func _save_zones() -> Dictionary:
	var zsm = get_node_or_null("/root/ZoneStreamingManager")
	if zsm:
		return {"current": zsm.current_zone, "loaded": zsm.loaded_zones.keys()}
	return {}

func _load_player(data: Dictionary):
	if data.is_empty():
		return
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	player.global_position = Vector3(
		data.get("position", {}).get("x", 0),
		data.get("position", {}).get("y", 0),
		data.get("position", {}).get("z", 0)
	)
	player.rotation.y = data.get("rotation_y", 0)
	player.flashlight_on = data.get("flashlight_on", false)
	player.flashlight_bat = data.get("flashlight_battery", 100.0)
	player.is_crouching = data.get("is_crouching", false)

func _load_inventory(data: Array):
	# Will be connected to inventory system
	pass

func _load_sanity(data: Dictionary):
	SanitySystem.sanity = data.get("sanity", 100.0)
	SanitySystem.is_in_safe_room = data.get("is_in_safe_room", false)

func _load_enemies(data: Dictionary):
	for enemy in get_tree().get_nodes_in_group("enemies"):
		var id = enemy.name
		if data.has(id):
			var e_data = data[id]
			enemy.global_position = Vector3(
				e_data.get("position", {}).get("x", 0),
				e_data.get("position", {}).get("y", 0),
				e_data.get("position", {}).get("z", 0)
			)
			if "state" in enemy:
				enemy.state = e_data.get("state", 0)
