extends Node

enum MusicState { CALM, TENSE, ALERT, CHASE, CAUGHT }

var current_state: MusicState = MusicState.CALM
var state_transition_times: Dictionary = {
	MusicState.CALM: 4.0,
	MusicState.TENSE: 2.0,
	MusicState.ALERT: 1.0,
	MusicState.CHASE: 0.3,
	MusicState.CAUGHT: 0.0,
}

var stem_players: Dictionary = {}
var reverb_buses: Dictionary = {}

const REVERB_BUS_NAMES = ["corridor", "classroom", "gym", "tunnel", "outdoor"]

func _ready():
	_setup_audio_buses()
	_setup_stem_players()
	EventBus.music_state_changed.connect(_on_music_state_changed)
	EventBus.enemy_chase_started.connect(_on_chase_started)
	EventBus.enemy_chase_ended.connect(_on_chase_ended)
	EventBus.enemy_catch_triggered.connect(_on_catch)
	EventBus.zone_entered.connect(_on_zone_changed)

func _setup_audio_buses():
	# Create reverb buses for each room type
	for bus_name in REVERB_BUS_NAMES:
		var bus_idx = AudioServer.bus_count
		AudioServer.add_bus()
		AudioServer.set_bus_name(bus_idx, "Reverb_" + bus_name)
		AudioServer.set_bus_send(bus_idx, "Master")
		reverb_buses[bus_name] = bus_idx

func _setup_stem_players():
	# Create audio players for each stem
	var stem_names = ["ambient", "low_strings", "percussion_soft", "percussion_full", "brass"]
	for stem in stem_names:
		var player = AudioStreamPlayer.new()
		player.name = "Stem_" + stem
		player.bus = "Master"
		add_child(player)
		stem_players[stem] = player

func _on_music_state_changed(new_state: String):
	match new_state:
		"calm": set_music_state(MusicState.CALM)
		"tense": set_music_state(MusicState.TENSE)
		"alert": set_music_state(MusicState.ALERT)
		"chase": set_music_state(MusicState.CHASE)
		"caught": set_music_state(MusicState.CAUGHT)

func set_music_state(new_state: MusicState):
	if current_state == new_state:
		return
	var transition_time = state_transition_times.get(new_state, 1.0)
	current_state = new_state

	match new_state:
		MusicState.CALM:
			_fade_stem("ambient", 0.0, transition_time)
			_fade_stem("low_strings", -80.0, transition_time)
			_fade_stem("percussion_soft", -80.0, transition_time)
			_fade_stem("percussion_full", -80.0, transition_time)
			_fade_stem("brass", -80.0, transition_time)
		MusicState.TENSE:
			_fade_stem("ambient", 0.0, transition_time)
			_fade_stem("low_strings", -10.0, transition_time)
			_fade_stem("percussion_soft", -80.0, transition_time)
			_fade_stem("percussion_full", -80.0, transition_time)
			_fade_stem("brass", -80.0, transition_time)
		MusicState.ALERT:
			_fade_stem("ambient", -5.0, transition_time)
			_fade_stem("low_strings", -5.0, transition_time)
			_fade_stem("percussion_soft", -10.0, transition_time)
			_fade_stem("percussion_full", -80.0, transition_time)
			_fade_stem("brass", -80.0, transition_time)
		MusicState.CHASE:
			_fade_stem("ambient", -10.0, transition_time)
			_fade_stem("low_strings", 0.0, transition_time)
			_fade_stem("percussion_soft", -5.0, transition_time)
			_fade_stem("percussion_full", 0.0, transition_time)
			_fade_stem("brass", -5.0, transition_time)
		MusicState.CAUGHT:
			_fade_stem("ambient", -80.0, 0.1)
			_fade_stem("low_strings", -80.0, 0.1)
			_fade_stem("percussion_soft", -80.0, 0.1)
			_fade_stem("percussion_full", -80.0, 0.1)
			_fade_stem("brass", -80.0, 0.1)
			# Play caught sting after brief silence
			await get_tree().create_timer(0.5).timeout
			_play_caught_sting()

func _fade_stem(stem_name: String, target_db: float, time: float):
	var player = stem_players.get(stem_name)
	if not player:
		return
	var tween = create_tween()
	tween.tween_property(player, "volume_db", target_db, time)

func _play_caught_sting():
	# Load and play the caught sting
	var player = AudioStreamPlayer.new()
	player.stream = load("res://audio/music/caught_sting.ogg")
	player.bus = "Master"
	add_child(player)
	player.play()
	await player.finished
	player.queue_free()

func _on_chase_started(_enemy_id: String):
	set_music_state(MusicState.CHASE)

func _on_chase_ended(_enemy_id: String):
	# Transition back through alert
	set_music_state(MusicState.ALERT)
	await get_tree().create_timer(10.0).timeout
	if current_state == MusicState.ALERT:
		set_music_state(MusicState.TENSE)

func _on_catch(_enemy_id: String):
	set_music_state(MusicState.CAUGHT)

func _on_zone_changed(zone_id: String):
	# Update reverb based on zone type
	var reverb_type = "corridor"  # default
	match zone_id:
		"main_building": reverb_type = "corridor"
		"science_wing": reverb_type = "classroom"
		"gymnasium": reverb_type = "gym"
		"maintenance": reverb_type = "tunnel"
		"exterior": reverb_type = "outdoor"
		"courtyard": reverb_type = "outdoor"
		"cafeteria": reverb_type = "corridor"
		"basement_lab": reverb_type = "tunnel"

	EventBus.ambient_changed.emit(zone_id)

func play_sfx(path: String, position: Vector3 = Vector3.ZERO):
	var player = AudioStreamPlayer3D.new()
	player.stream = load(path)
	player.global_position = position
	player.max_distance = 30.0
	player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	add_child(player)
	player.play()
	await player.finished
	player.queue_free()

func update_based_on_enemies():
	# Check enemy states to determine music
	var any_chasing = false
	var any_alert = false
	var any_nearby = false

	for enemy in get_tree().get_nodes_in_group("enemies"):
		if "state" in enemy:
			var state_name = enemy.state
			if state_name == 4:  # CHASE
				any_chasing = true
			elif state_name == 3:  # ALERT
				any_alert = true
			elif state_name == 2:  # SEARCH
				any_nearby = true

	if any_chasing:
		set_music_state(MusicState.CHASE)
	elif any_alert:
		set_music_state(MusicState.ALERT)
	elif any_nearby:
		set_music_state(MusicState.TENSE)
	else:
		set_music_state(MusicState.CALM)
