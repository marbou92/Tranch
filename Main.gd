extends Node3D

@export var player_scene: PackedScene

func _ready() -> void:
	_setup_horror_environment()
	_spawn_player()
	_setup_ambient_audio()
	_connect_horror_signals()

func _setup_horror_environment() -> void:
	var world_env: WorldEnvironment = get_node_or_null("WorldEnvironment")
	if not world_env:
		world_env = WorldEnvironment.new()
		world_env.name = "WorldEnvironment"
		add_child(world_env)
	world_env.add_to_group("world_environment")

	var env: Environment = world_env.environment
	if not env:
		env = Environment.new()
		world_env.environment = env

	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.01, 0.01, 0.02)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.04, 0.03, 0.06)
	env.ambient_light_energy = 0.25
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 0.7
	env.fog_enabled = true
	env.fog_light_color = Color(0.02, 0.02, 0.04)
	env.fog_depth_begin = 3.0
	env.fog_depth_end = 25.0
	env.fog_depth_curve = 1.5
	env.volumetric_fog_enabled = true
	env.volumetric_fog_density = 0.02
	env.volumetric_fog_albedo = Color(0.02, 0.02, 0.04)

func _spawn_player() -> void:
	if player_scene:
		var player: Node3D = player_scene.instantiate()
		add_child(player)
		var spawn: Marker3D = get_node_or_null("PlayerSpawn")
		if spawn:
			player.global_position = spawn.global_position

func _setup_ambient_audio() -> void:
	var audio_player: AudioStreamPlayer = AudioStreamPlayer.new()
	audio_player.name = "AmbientAudio"
	audio_player.autoplay = true
	audio_player.volume_db = -15.0
	audio_player.bus = "Ambient"
	add_child(audio_player)

func _connect_horror_signals() -> void:
	if HorrorManager and HorrorManager.has_signal("scare_triggered"):
		HorrorManager.scare_triggered.connect(_on_scare_triggered)

func _on_scare_triggered(scare_name: String) -> void:
	match scare_name:
		"locker_bang":
			_shake_camera(0.3, 0.15)
		"school_bell":
			_shake_camera(0.1, 0.05)
		"locker_slam":
			_shake_camera(0.4, 0.2)
		_:
			pass

func _shake_camera(intensity: float, duration: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("Head/Camera3D"):
		var cam: Camera3D = player.get_node("Head/Camera3D")
		var tween: Tween = create_tween()
		var orig_pos: Vector3 = cam.position
		for i in range(5):
			var offset: Vector3 = Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * intensity
			tween.tween_property(cam, "position", orig_pos + offset, duration / 5)
		tween.tween_property(cam, "position", orig_pos, duration / 5)
