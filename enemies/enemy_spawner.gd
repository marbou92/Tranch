extends Node3D

# Enemy scene references — these will be loaded lazily when the scenes
# exist (M1 will create janitor.tscn, M3 creates crawler.tscn, M5 creates
# teacher.tscn). Using lazy load() instead of preload() so the spawner
# script can compile without the scenes existing yet.
const JANITOR_SCENE_PATH = "res://enemies/janitor.tscn"
const CRAWLER_SCENE_PATH = "res://enemies/crawler.tscn"
const TEACHER_SCENE_PATH = "res://enemies/teacher.tscn"

var spawned_enemies: Dictionary = {}


func _load_scene(path: String) -> PackedScene:
	if not ResourceLoader.exists(path):
		push_warning("Enemy spawner: scene not found at " + path + " — skipping spawn")
		return null
	return load(path)


func _ready():
	EventBus.zone_loaded.connect(_on_zone_loaded)
	EventBus.zone_unloaded.connect(_on_zone_unloaded)


func _on_zone_loaded(zone_id: String):
	match zone_id:
		"main_building", "science_wing", "gymnasium", "cafeteria", "maintenance":
			_spawn_janitor_if_needed(zone_id)
		"science_wing":
			_spawn_crawlers(zone_id)
		"basement_lab":
			_spawn_teacher(zone_id)


func _on_zone_unloaded(zone_id: String):
	_despawn_enemies_in_zone(zone_id)


func _spawn_janitor_if_needed(zone_id: String):
	if "janitor" not in spawned_enemies or not is_instance_valid(spawned_enemies["janitor"]):
		var janitor_scene = _load_scene(JANITOR_SCENE_PATH)
		if janitor_scene == null:
			return

			# Find a patrol waypoint to spawn at
		var janitor = janitor_scene.instantiate()
		# Find a patrol waypoint to spawn at
		var zones = get_tree().get_nodes_in_group("zones")
		for zone in zones:
			if zone.has_method("get_patrol_waypoints"):
				var wps = zone.get_patrol_waypoints()
				if wps.size() > 0:
					janitor.global_position = wps[0].global_position
					break
		get_tree().current_scene.add_child(janitor)
		spawned_enemies["janitor"] = janitor


func _spawn_crawlers(zone_id: String):
	# Find crawler nest markers in the zone
	var zones = get_tree().get_nodes_in_group("zones")
	for zone in zones:
		if zone.zone_id == "science_wing" and zone.has_node("CrawlerNests"):
			for nest in zone.get_node("CrawlerNests").get_children():
				if nest is Marker3D:
					var crawler_scene = _load_scene(CRAWLER_SCENE_PATH)
					if crawler_scene == null:
						return
					var crawler = crawler_scene.instantiate()
					crawler.global_position = nest.global_position
					get_tree().current_scene.add_child(crawler)
					if not spawned_enemies.has("crawlers"):
						spawned_enemies["crawlers"] = []
					spawned_enemies["crawlers"].append(crawler)


func _spawn_teacher(zone_id: String):
	if "teacher" not in spawned_enemies or not is_instance_valid(spawned_enemies["teacher"]):
		var teacher_scene = _load_scene(TEACHER_SCENE_PATH)
		if teacher_scene == null:
			return
		var teacher = teacher_scene.instantiate()
		# Find teacher spawn point in basement lab
		var zones = get_tree().get_nodes_in_group("zones")
		for zone in zones:
			if zone.zone_id == "basement_lab" and zone.has_node("TeacherSpawnPoint"):
				teacher.global_position = zone.get_node("TeacherSpawnPoint").global_position
				break
		get_tree().current_scene.add_child(teacher)
		spawned_enemies["teacher"] = teacher


func _despawn_enemies_in_zone(zone_id: String):
	# Don't despawn the janitor - it moves between zones
	# Despawn zone-specific enemies
	if zone_id == "science_wing" and spawned_enemies.has("crawlers"):
		for crawler in spawned_enemies["crawlers"]:
			if is_instance_valid(crawler):
				crawler.queue_free()
		spawned_enemies.erase("crawlers")
