extends Node3D

enum State { DORMANT, TRIGGERED, LUNGE, RETREAT }

const TRIGGER_RADIUS = 0.8
const LUNGE_SPEED = 9.0
const LUNGE_RANGE = 1.5
const RETREAT_TIME = 4.0
const FLASHLIGHT_RETREAT_TIME = 2.0
const DAMAGE_SANITY = 15.0

@onready var trigger_area = $TriggerArea
@onready var lunge_target = $LungeTarget
@onready var anim = $AnimationPlayer
@onready var click_audio = $ClickAudio

var state: State = State.DORMANT
var lunge_origin: Vector3 = Vector3.ZERO
var retreat_timer: float = 0.0
var flashlight_timer: float = 0.0
var player_ref: Node3D = null

signal crawler_triggered
signal crawler_lunge_hit


func _ready():
	add_to_group("enemies")
	add_to_group("crawlers")
	lunge_origin = global_position

	if trigger_area:
		trigger_area.body_entered.connect(_on_body_entered_trigger)

	await get_tree().create_timer(0.5).timeout
	player_ref = get_tree().get_first_node_in_group("player")


func _process(delta):
	match state:
		State.DORMANT:
			_check_flashlight(delta)
		State.TRIGGERED:
			_start_lunge()
		State.LUNGE:
			_tick_lunge(delta)
		State.RETREAT:
			_tick_retreat(delta)


func _on_body_entered_trigger(body: Node3D):
	if body.is_in_group("player") and state == State.DORMANT:
		state = State.TRIGGERED
		crawler_triggered.emit()


func _check_flashlight(delta):
	if not player_ref:
		return
	# Check if player's flashlight is aimed at this crawler
	if player_ref.flashlight_on:
		var to_crawler = global_position - player_ref.global_position
		var look_dir = -player_ref.camera.global_basis.z
		var angle = rad_to_deg(look_dir.angle_to(to_crawler.normalized()))
		if angle < 15.0:  # Within flashlight cone
			flashlight_timer += delta
			if flashlight_timer >= FLASHLIGHT_RETREAT_TIME:
				_retreat_slightly()
				flashlight_timer = 0.0
		else:
			flashlight_timer = 0.0


func _start_lunge():
	state = State.LUNGE
	anim.play("lunge")
	click_audio.stream = load("res://audio/enemies/crawler_click.ogg")
	click_audio.play()
	# High-pass filtered binaural click
	var dist_to_player = global_position.distance_to(player_ref.global_position)
	click_audio.volume_db = -10.0 + (1.0 - min(dist_to_player / 5.0, 1.0)) * 20.0


func _tick_lunge(delta):
	if not player_ref:
		state = State.RETREAT
		return

	var target_pos = player_ref.global_position
	var dir = (target_pos - global_position).normalized()
	global_position += dir * LUNGE_SPEED * delta

	var dist = global_position.distance_to(target_pos)
	if dist < 0.5:
		# Hit player
		crawler_lunge_hit.emit()
		SanitySystem.drain_entity(delta)
		GameState.player_died("crawler")
		state = State.RETREAT
	elif global_position.distance_to(lunge_origin) > LUNGE_RANGE:
		# Missed
		state = State.RETREAT
		retreat_timer = RETREAT_TIME


func _tick_retreat(delta):
	retreat_timer -= delta
	# Slowly move back toward origin
	var dir = (lunge_origin - global_position).normalized()
	global_position += dir * 1.0 * delta

	if retreat_timer <= 0:
		global_position = lunge_origin
		state = State.DORMANT
		anim.play("dormant")


func _retreat_slightly():
	var away_from_player = (global_position - player_ref.global_position).normalized()
	global_position += away_from_player * 0.3
	flashlight_timer = 0.0
