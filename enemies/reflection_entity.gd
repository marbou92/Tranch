extends Node3D

const SANITY_DRAIN_RATE = 0.3
const SANITY_TRIGGER_THRESHOLD = 60.0
const LOOK_DIRECTLY_TIME = 3.0
const MOVEMENT_DELAY_MIN = 1.0
const MOVEMENT_DELAY_MAX = 2.0

var is_active: bool = false
var look_timer: float = 0.0
var movement_delay: float = 1.5
var delayed_position: Vector3 = Vector3.ZERO
var delayed_rotation: float = 0.0
var player_ref: Node3D = null

@onready var reflection_mesh = $ReflectionMesh
@onready var anim = $AnimationPlayer

signal reflection_appeared
signal reflection_disappeared


func _ready():
	add_to_group("enemies")
	add_to_group("reflections")
	visible = false
	await get_tree().create_timer(0.5).timeout
	player_ref = get_tree().get_first_node_in_group("player")
	EventBus.player_sanity_changed.connect(_on_sanity_changed)


func _process(delta):
	if not is_active:
		return

	_update_reflection_position(delta)
	_check_player_looking(delta)
	_drain_sanity(delta)


func _on_sanity_changed(value: float):
	if value < SANITY_TRIGGER_THRESHOLD and not is_active:
		_activate()
	elif value >= SANITY_TRIGGER_THRESHOLD and is_active:
		_deactivate()


func _activate():
	is_active = true
	visible = true
	movement_delay = randf_range(MOVEMENT_DELAY_MIN, MOVEMENT_DELAY_MAX)
	reflection_appeared.emit()
	# More aggressive at lower sanity
	if SanitySystem.sanity < 30:
		anim.play("aggressive")
	else:
		anim.play("subtle")


func _deactivate():
	is_active = false
	visible = false
	look_timer = 0.0
	reflection_disappeared.emit()


func _update_reflection_position(delta):
	if not player_ref:
		return

	# Store delayed position for mimicry
	delayed_position = player_ref.global_position
	delayed_rotation = player_ref.rotation.y

	# Apply with delay (mirror position)
	await get_tree().create_timer(movement_delay).timeout
	if not is_active:
		return

	# Mirror the player's position relative to the reflection surface
	var mirror_pos = _calculate_mirror_position(delayed_position)
	global_position = lerp(global_position, mirror_pos, delta * 2.0)
	rotation.y = -delayed_rotation  # Mirror rotation

	# Introduce wrong movements at low sanity
	if SanitySystem.sanity < 30 and randf() < 0.01:
		_add_wrong_movement()
	if SanitySystem.sanity < 15 and randf() < 0.02:
		_gesture_at_player()


func _calculate_mirror_position(player_pos: Vector3) -> Vector3:
	# Simple mirror: reflect across the surface this reflection is on
	# This is a placeholder; actual mirror surface detection would be more complex
	var to_player = player_pos - global_position
	return global_position + Vector3(-to_player.x, to_player.y, -to_player.z) * 0.5


func _check_player_looking(delta):
	if not player_ref or not player_ref.has_node("Camera3D"):
		return

	var camera = player_ref.camera
	var to_reflection = global_position - camera.global_position
	var look_dir = -camera.global_basis.z
	var angle = rad_to_deg(look_dir.angle_to(to_reflection.normalized()))

	if angle < 10.0:  # Player looking directly at reflection
		look_timer += delta
		if look_timer >= LOOK_DIRECTLY_TIME:
			_deactivate()
	else:
		look_timer = max(0, look_timer - delta * 2.0)
		# If player looks away entirely for a while, also deactivate
		if angle > 90.0:
			look_timer -= delta
			if look_timer < -2.0:
				_deactivate()


func _drain_sanity(delta):
	if is_active:
		SanitySystem.drain_entity(delta * SANITY_DRAIN_RATE / 1.8)


func _add_wrong_movement():
	# Slight offset in wrong direction
	var offset = Vector3(randf_range(-0.5, 0.5), randf_range(-0.2, 0.2), randf_range(-0.5, 0.5))
	global_position += offset


func _gesture_at_player():
	anim.play("gesture")
