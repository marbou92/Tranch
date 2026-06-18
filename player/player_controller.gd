extends CharacterBody3D

const WALK_SPEED = 2.8
const CROUCH_SPEED = 1.2
const SPRINT_SPEED = 5.6
const GRAVITY = 9.8
const MOUSE_SENS = 0.2
const SPRINT_MAX = 3.0
const SPRINT_COOL = 6.0
const CROUCH_HEIGHT = 1.1
const STAND_HEIGHT = 1.8
const STEP_HEIGHT = 0.35
const INTERACTION_RANGE = 1.8

@onready var camera = $Camera3D
@onready var col_shape = $CollisionShape3D
@onready var noise_bus = $NoiseBus
@onready var head_bob = $HeadBob
@onready var interaction_ray = $Camera3D/InteractionRayCast3D
@onready var flashlight_spot = $Camera3D/FlashlightSpotLight3D
@onready var flashlight_audio = $FlashlightAudio

var sprint_timer: float = 0.0
var sprint_cooldown: float = 0.0
var is_crouching: bool = false
var is_sprinting: bool = false
var flashlight_bat: float = 100.0
var flashlight_on: bool = false
var flashlight_dim: bool = false
var sanity: float = 100.0
var head_bob_time: float = 0.0
var interaction_target: Node3D = null

signal noise_emitted(radius: float, origin: Vector3)
signal sanity_changed(value: float)
signal flashlight_toggled(state: bool)
signal interacted_with(node: Node3D)

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	sprint_timer = SPRINT_MAX
	add_to_group("player")

func _unhandled_input(event):
	if event is InputEventMouseMotion:
		rotate_y(-event.relative.x * MOUSE_SENS * 0.01)
		camera.rotate_x(-event.relative.y * MOUSE_SENS * 0.01)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-85), deg_to_rad(85))
	
	if event.is_action_pressed("toggle_flashlight"):
		_toggle_flashlight()
	if event.is_action_pressed("toggle_crouch"):
		_toggle_crouch()
	if event.is_action_pressed("interact"):
		_try_interact()
	if event.is_action_pressed("flashlight_dim"):
		flashlight_dim = !flashlight_dim
		_update_flashlight_mode()

func _physics_process(delta):
	_handle_gravity(delta)
	_handle_movement(delta)
	_handle_flashlight(delta)
	_handle_sanity(delta)
	_handle_head_bob(delta)
	_update_interaction()
	move_and_slide()

func _handle_movement(delta):
	var input = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_forward", "move_back")
	).normalized()
	
	is_sprinting = Input.is_action_pressed("sprint") \
		and sprint_timer > 0 \
		and not is_crouching \
		and input.length() > 0.1
	
	if is_sprinting:
		sprint_timer = max(0, sprint_timer - delta)
		if sprint_timer == 0:
			sprint_cooldown = SPRINT_COOL
	else:
		if sprint_cooldown > 0:
			sprint_cooldown -= delta
		else:
			sprint_timer = min(SPRINT_MAX, sprint_timer + delta * 0.5)
	
	var speed = SPRINT_SPEED if is_sprinting \
		else CROUCH_SPEED if is_crouching \
		else WALK_SPEED
	
	var dir = (transform.basis * Vector3(input.x, 0, input.y)).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	_emit_movement_noise(speed)

func _emit_movement_noise(speed):
	var radius = 0.0
	if speed >= SPRINT_SPEED:
		radius = 8.0
	elif speed >= WALK_SPEED:
		radius = 3.0
	elif speed >= CROUCH_SPEED:
		radius = 1.5
	if radius > 0:
		noise_emitted.emit(radius, global_position)
		EventBus.player_noise_emitted.emit(radius, global_position)

func _handle_gravity(delta):
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

func _toggle_flashlight():
	if flashlight_bat <= 0:
		return
	flashlight_on = !flashlight_on
	flashlight_spot.visible = flashlight_on
	flashlight_toggled.emit(flashlight_on)
	EventBus.player_flashlight_toggled.emit(flashlight_on)
	if flashlight_on:
		noise_emitted.emit(0.5, global_position)
		flashlight_audio.play()

func _update_flashlight_mode():
	if flashlight_on:
		flashlight_spot.spot_angle = 25.0 if flashlight_dim else 45.0
		flashlight_spot.spot_energy = 2.0 if flashlight_dim else 4.0

func _handle_flashlight(delta):
	if flashlight_on:
		var drain = 1.5 if not flashlight_dim else 0.6
		flashlight_bat = max(0, flashlight_bat - drain * delta)
		if flashlight_bat == 0:
			flashlight_on = false
			flashlight_spot.visible = false
			flashlight_toggled.emit(false)

func _handle_sanity(delta):
	if not flashlight_on:
		sanity = max(0, sanity - 0.4 * delta)
	else:
		sanity = min(100, sanity + 0.1 * delta)
	sanity_changed.emit(sanity)
	EventBus.player_sanity_changed.emit(sanity)

func _toggle_crouch():
	is_crouching = !is_crouching
	var tween = create_tween()
	var h = CROUCH_HEIGHT if is_crouching else STAND_HEIGHT
	tween.tween_property(col_shape, "shape:height", h, 0.2)
	# Adjust camera position for crouch
	var cam_y = 0.5 if is_crouching else 0.8
	tween.parallel().tween_property(camera, "position:y", cam_y, 0.2)

func _handle_head_bob(delta):
	if not is_on_floor():
		return
	var speed = Vector2(velocity.x, velocity.z).length()
	if speed < 0.5:
		head_bob_time = 0.0
		camera.position.y = lerp(camera.position.y, 0.8 if not is_crouching else 0.5, delta * 8.0)
		return
	
	head_bob_time += delta * speed * 1.5
	var bob_amount = 0.02 if is_crouching else 0.04 if is_sprinting else 0.025
	var bob_y = sin(head_bob_time) * bob_amount
	var bob_x = cos(head_bob_time * 0.5) * bob_amount * 0.5
	camera.position.y += bob_y
	camera.position.x = lerp(camera.position.x, bob_x, delta * 6.0)

func _update_interaction():
	interaction_ray.force_raycast_update()
	if interaction_ray.is_colliding():
		var collider = interaction_ray.get_collider()
		if collider and collider.has_method("interact"):
			interaction_target = collider
			var hint_text = collider.get_interaction_text() if collider.has_method("get_interaction_text") else "E — Interact"
			EventBus.interaction_hint_show.emit(hint_text)
		else:
			_clear_interaction()
	else:
		_clear_interaction()

func _clear_interaction():
	if interaction_target != null:
		EventBus.interaction_hint_hide.emit()
		interaction_target = null

func _try_interact():
	if interaction_target and interaction_target.has_method("interact"):
		interaction_target.interact(self)
		interacted_with.emit(interaction_target)

func restore_sanity(amount: float):
	sanity = min(100, sanity + amount)

func drain_sanity(amount: float):
	sanity = max(0, sanity - amount)

func add_battery(amount: float):
	flashlight_bat = min(100, flashlight_bat + amount)
