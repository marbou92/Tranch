extends CharacterBody3D

enum State { PATROL, PURSUIT, SEARCH, CATCH, RESET }

const WALK_SPEED = 1.6
const ALERT_SPEED = 3.9
const HEARING_RANGE = 12.0
const SEARCH_TIME = 60.0
const CATCH_DIST = 0.5
const CARPET_NOISE_REDUCTION = 0.4
const EXHALE_DIST = 3.0

@onready var nav_agent = $NavigationAgent3D
@onready var anim = $AnimationPlayer
@onready var exhale_audio = $ExhaleAudio

var state: State = State.PATROL
var patrol_points: Array = []
var patrol_idx: int = 0
var last_known_pos: Vector3 = Vector3.ZERO
var search_timer: float = 0.0
var player_ref: Node3D = null
var heard_position: Vector3 = Vector3.ZERO

signal player_caught

func _ready():
	add_to_group("enemies")
	add_to_group("teacher")
	_find_patrol_points()
	await get_tree().create_timer(0.5).timeout
	player_ref = get_tree().get_first_node_in_group("player")
	if player_ref:
		player_ref.noise_emitted.connect(_on_noise)
	_set_state(State.PATROL)

func _find_patrol_points():
	patrol_points.clear()
	for wp in get_tree().get_nodes_in_group("teacher_waypoints"):
		if wp is Marker3D:
			patrol_points.append(wp)
	if patrol_points.is_empty():
		for i in range(4):
			var marker = Marker3D.new()
			var angle = i * PI / 2
			marker.global_position = global_position + Vector3(cos(angle) * 4, 0, sin(angle) * 4)
			patrol_points.append(marker)

func _physics_process(delta):
	# Teacher only exists in basement_lab
	if GameState.current_zone != "basement_lab":
		return
	
	match state:
		State.PATROL: _tick_patrol(delta)
		State.PURSUIT: _tick_pursuit(delta)
		State.SEARCH: _tick_search(delta)
		State.CATCH: _tick_catch(delta)
		State.RESET: _tick_reset(delta)
	
	_check_proximity_exhale()
	move_and_slide()

func _tick_patrol(_delta):
	if patrol_points.is_empty():
		return
	nav_agent.set_target_position(patrol_points[patrol_idx].global_position)
	_move_toward_target(WALK_SPEED)
	if nav_agent.is_navigation_finished():
		patrol_idx = (patrol_idx + 1) % patrol_points.size()

func _tick_pursuit(_delta):
	if not player_ref:
		return
	last_known_pos = player_ref.global_position
	nav_agent.set_target_position(last_known_pos)
	_move_toward_target(ALERT_SPEED)
	
	if global_position.distance_to(player_ref.global_position) < CATCH_DIST:
		_set_state(State.CATCH)

func _tick_search(delta):
	search_timer -= delta
	if search_timer <= 0:
		_set_state(State.RESET)
		return
	if nav_agent.is_navigation_finished():
		var offset = Vector3(randf_range(-4, 4), 0, randf_range(-4, 4))
		nav_agent.set_target_position(last_known_pos + offset)
	_move_toward_target(WALK_SPEED)

func _tick_catch(_delta):
	player_caught.emit()
	EventBus.enemy_catch_triggered.emit("teacher")
	GameState.player_died("teacher")

func _tick_reset(_delta):
	if patrol_points.is_empty():
		return
	nav_agent.set_target_position(patrol_points[patrol_idx].global_position)
	_move_toward_target(WALK_SPEED)
	if nav_agent.is_navigation_finished():
		_set_state(State.PATROL)

func _on_noise(radius: float, origin: Vector3):
	# Teacher has perfect hearing within 12m
	# Carpet in basement reduces effective noise radius by 40%
	var effective_radius = radius * (1.0 - CARPET_NOISE_REDUCTION)
	var dist = global_position.distance_to(origin)
	
	if dist <= HEARING_RANGE and effective_radius > 0.5:
		heard_position = origin
		last_known_pos = origin
		if state == State.PATROL:
			_set_state(State.PURSUIT)
		elif state == State.SEARCH:
			_set_state(State.PURSUIT)

func _check_proximity_exhale():
	if not player_ref:
		return
	var dist = global_position.distance_to(player_ref.global_position)
	
	if dist <= EXHALE_DIST:
		if not exhale_audio.playing:
			exhale_audio.stream = load("res://audio/enemies/teacher_exhale.ogg")
			exhale_audio.play()
			exhale_audio.volume_db = -15.0
	else:
		if exhale_audio.playing:
			exhale_audio.stop()
	
	# Teacher's own footsteps are inaudible - the player's heartbeat is the only proximity cue
	# This is handled by the sanity/audio system, not here

func _set_state(new_state: State):
	state = new_state
	match state:
		State.PATROL:
			anim.play("slow_walk")
		State.PURSUIT:
			anim.play("fast_walk")
			EventBus.enemy_chase_started.emit("teacher")
		State.SEARCH:
			search_timer = SEARCH_TIME
			anim.play("search")
		State.CATCH:
			anim.play("catch")
		State.RESET:
			anim.play("slow_walk")
			EventBus.enemy_chase_ended.emit("teacher")

func _move_toward_target(speed: float):
	var next = nav_agent.get_next_path_position()
	var dir = (next - global_position).normalized()
	velocity = dir * speed
	velocity.y = 0
	if dir.length() > 0.1:
		var target_rot = atan2(dir.x, dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot, 0.08)
