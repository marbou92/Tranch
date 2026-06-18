extends CharacterBody3D
class_name EnemyBase

enum DetectionType { VISION, SOUND, PROXIMITY }

@export var enemy_id: String = ""
@export var enemy_name: String = ""
@export var walk_speed: float = 2.0
@export var alert_speed: float = 4.0
@export var chase_speed: float = 6.0
@export var detection_type: DetectionType = DetectionType.VISION
@export var vision_range: float = 15.0
@export var hearing_range: float = 10.0
@export var search_duration: float = 30.0
@export var memory_duration: float = 45.0
@export var catch_distance: float = 0.5
@export var can_enter_exterior: bool = false

var is_active: bool = true
var current_state: String = "patrol"


func _ready():
	add_to_group("enemies")


func can_operate_in_zone(zone_id: String) -> bool:
	if zone_id == "exterior" and not can_enter_exterior:
		return false
	return true


func _on_distract(position: Vector3):
	pass


func _on_player_spotted():
	pass


func deactivate():
	is_active = false
	set_physics_process(false)


func activate():
	is_active = true
	set_physics_process(true)
