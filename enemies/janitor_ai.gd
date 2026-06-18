extends CharacterBody3D

enum State { PATROL, INVESTIGATE, SEARCH, ALERT, CHASE, CATCH, RESET }

const WALK_SPEED = 2.1
const ALERT_SPEED = 4.8
const CHASE_SPEED = 6.2
const VISION_RANGE = 20.0
const VISION_ANGLE = 65.0
const SEARCH_TIME = 30.0
const MEMORY_TIME = 45.0
const CATCH_DIST = 0.5
const AMBIENT_VISION_RANGE = 12.0
const SOUND_INVESTIGATE_RANGE = 8.0

@onready var nav_agent = $NavigationAgent3D
@onready var anim = $AnimationPlayer
@onready var audio = $AudioStreamPlayer3D
@onready var sight_ray = $SightRayCast3D
@onready var radio_audio = $RadioAudio

var state: State = State.PATROL
var patrol_points: Array = []
var patrol_idx: int = 0
var last_known_pos: Vector3 = Vector3.ZERO
var search_timer: float = 0.0
var memory_timer: float = 0.0
var player_ref: Node3D = null
var heard_position: Vector3 = Vector3.ZERO
var alert_timer: float = 0.0
var hide_timer: float = 0.0
var player_was_visible: bool = false
var _patrol_zone: String = ""

signal player_caught

func _ready():
        add_to_group("enemies")
        add_to_group("janitor")
        # Find patrol points in current zone
        _find_patrol_points()
        # Connect to player noise
        await get_tree().create_timer(0.5).timeout
        player_ref = get_tree().get_first_node_in_group("player")
        if player_ref:
                player_ref.noise_emitted.connect(_on_noise)
        _set_state(State.PATROL)

func _find_patrol_points():
        patrol_points.clear()
        var zones = get_tree().get_nodes_in_group("zones")
        for zone in zones:
                if zone.has_method("get_patrol_waypoints"):
                        var wps = zone.get_patrol_waypoints()
                        if wps.size() > 0:
                                patrol_points.append_array(wps)
        # Also check for janitor waypoints group
        for wp in get_tree().get_nodes_in_group("janitor_waypoints"):
                if wp is Marker3D:
                        patrol_points.append(wp)
        if patrol_points.is_empty():
                # Generate default patrol points around current position
                for i in range(4):
                        var marker = Marker3D.new()
                        var angle = i * PI / 2
                        marker.global_position = global_position + Vector3(cos(angle) * 5, 0, sin(angle) * 5)
                        patrol_points.append(marker)

func _physics_process(delta):
        # Check if we're in an exterior zone (Janitor cannot enter)
        if GameState.current_zone == "exterior":
                _set_state(State.RESET)
                return
        
        match state:
                State.PATROL: _tick_patrol(delta)
                State.INVESTIGATE: _tick_investigate(delta)
                State.SEARCH: _tick_search(delta)
                State.ALERT: _tick_alert(delta)
                State.CHASE: _tick_chase(delta)
                State.CATCH: _tick_catch(delta)
                State.RESET: _tick_reset(delta)
        
        _check_vision()
        _update_audio_cues()
        move_and_slide()

func _tick_patrol(_delta):
        if patrol_points.is_empty():
                return
        nav_agent.set_target_position(patrol_points[patrol_idx].global_position)
        _move_toward_target(WALK_SPEED)
        if nav_agent.is_navigation_finished():
                patrol_idx = (patrol_idx + 1) % patrol_points.size()

func _tick_investigate(_delta):
        nav_agent.set_target_position(heard_position)
        _move_toward_target(WALK_SPEED)
        if nav_agent.is_navigation_finished():
                last_known_pos = heard_position
                _set_state(State.SEARCH)

func _tick_search(delta):
        search_timer -= delta
        if search_timer <= 0:
                _set_state(State.RESET)
                return
        if nav_agent.is_navigation_finished():
                var offset = Vector3(randf_range(-6, 6), 0, randf_range(-6, 6))
                nav_agent.set_target_position(last_known_pos + offset)
        _move_toward_target(WALK_SPEED)

func _tick_alert(delta):
        alert_timer -= delta
        look_at(Vector3(last_known_pos.x, global_position.y, last_known_pos.z), Vector3.UP)
        if alert_timer <= 0:
                _set_state(State.CHASE)

func _tick_chase(_delta):
        if not player_ref:
                return
        last_known_pos = player_ref.global_position
        memory_timer = MEMORY_TIME
        nav_agent.set_target_position(last_known_pos)
        _move_toward_target(CHASE_SPEED)
        
        # Check catch distance
        if global_position.distance_to(player_ref.global_position) < CATCH_DIST:
                _set_state(State.CATCH)
        
        # Check if player is hidden (not moving, in safe spot, out of sight)
        var dist_to_player = global_position.distance_to(player_ref.global_position)
        if dist_to_player > VISION_RANGE:
                hide_timer += get_process_delta_time()
                if hide_timer >= 8.0:
                        _set_state(State.SEARCH)
        else:
                hide_timer = 0.0

func _tick_catch(_delta):
        player_caught.emit()
        EventBus.enemy_catch_triggered.emit("janitor")
        GameState.player_died("janitor")

func _tick_reset(_delta):
        if patrol_points.is_empty():
                return
        nav_agent.set_target_position(patrol_points[patrol_idx].global_position)
        _move_toward_target(WALK_SPEED)
        if nav_agent.is_navigation_finished():
                _set_state(State.PATROL)

func _check_vision():
        if not player_ref:
                return
        var to_player = player_ref.global_position - global_position
        var dist = to_player.length()
        
        # Determine effective vision range
        var effective_range = AMBIENT_VISION_RANGE
        if player_ref.flashlight_on:
                effective_range = VISION_RANGE
        
        if dist > effective_range:
                return
        
        var angle = rad_to_deg(global_transform.basis.z.angle_to(to_player.normalized()))
        if angle > VISION_ANGLE:
                return
        
        sight_ray.target_position = to_player
        sight_ray.force_raycast_update()
        if not sight_ray.is_colliding() or sight_ray.get_collider() == player_ref:
                _on_player_spotted()

func _on_player_spotted():
        last_known_pos = player_ref.global_position
        if state not in [State.CHASE, State.CATCH]:
                _set_state(State.ALERT)

func _on_noise(radius: float, origin: Vector3):
        var dist = global_position.distance_to(origin)
        if dist <= radius and state not in [State.CHASE, State.CATCH]:
                heard_position = origin
                _set_state(State.INVESTIGATE)

func _set_state(new_state: State):
        state = new_state
        match state:
                State.PATROL:
                        anim.play("walk")
                        _safe_load_audio("res://audio/enemies/janitor_ambient.ogg")
                        audio.play()
                State.INVESTIGATE:
                        anim.play("walk")
                State.SEARCH:
                        search_timer = SEARCH_TIME
                        anim.play("look_around")
                State.ALERT:
                        anim.play("alert")
                        alert_timer = 0.8
                        _safe_load_audio("res://audio/enemies/janitor_alert.ogg")
                        audio.play()
                State.CHASE:
                        anim.play("run")
                        _safe_load_audio("res://audio/enemies/janitor_chase.ogg")
                        audio.play()
                        hide_timer = 0.0
                        EventBus.enemy_chase_started.emit("janitor")
                State.CATCH:
                        anim.play("catch")
                        player_caught.emit()
                State.RESET:
                        anim.play("walk")
                        EventBus.enemy_chase_ended.emit("janitor")

func _safe_load_audio(path: String) -> void:
        # Defensive loader: silently skip if the audio asset is missing
        # (placeholder until /assets/ is populated — see /assets/MANIFEST.md)
        if not ResourceLoader.exists(path):
                push_warning("Missing audio: %s — using silent placeholder" % path)
                return
        var stream = load(path)
        if stream:
                audio.stream = stream

func _move_toward_target(speed: float):
        var next = nav_agent.get_next_path_position()
        var dir = (next - global_position).normalized()
        velocity = dir * speed
        velocity.y = 0
        if dir.length() > 0.1:
                var target_rot = atan2(dir.x, dir.z)
                rotation.y = lerp_angle(rotation.y, target_rot, 0.12)

func _update_audio_cues():
        if not player_ref:
                return
        var dist = global_position.distance_to(player_ref.global_position)
        
        # Radio static
        if radio_audio:
                if dist <= 20.0 and dist > 5.0:
                        radio_audio.volume_db = -20.0 + (20.0 - dist) * 1.5
                        if not radio_audio.playing:
                                radio_audio.play()
                elif dist <= 5.0:
                        radio_audio.volume_db = 0.0
                else:
                        radio_audio.stop()
        
        # Ambient footsteps based on distance
        if audio:
                if dist <= 15.0:
                        audio.volume_db = -30.0 + (15.0 - dist) * 2.5
                else:
                        audio.volume_db = -60.0

func distract(position: Vector3):
        """Called when player throws a distraction stone"""
        if state in [State.PATROL, State.INVESTIGATE]:
                heard_position = position
                _set_state(State.INVESTIGATE)
