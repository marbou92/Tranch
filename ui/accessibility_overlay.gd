extends CanvasLayer

@onready var subtitle_box = $SubtitleBox
@onready var audio_indicator = $AudioIndicator
@onready var direction_indicator = $DirectionIndicator

var subtitles_enabled: bool = true
var audio_indicators_enabled: bool = false
var subtitle_queue: Array = []
var current_subtitle_timer: float = 0.0

func _ready():
	EventBus.play_sfx.connect(_on_sfx_played)
	# Connect to subtitle events
	# Audio indicator shows directional arrows for nearby sounds

func _process(delta):
	if current_subtitle_timer > 0:
		current_subtitle_timer -= delta
		if current_subtitle_timer <= 0:
			subtitle_box.visible = false
			_show_next_subtitle()

func show_subtitle(text: String, duration: float = 3.0):
	if not subtitles_enabled:
		return
	subtitle_queue.append({"text": text, "duration": duration})
	if current_subtitle_timer <= 0:
		_show_next_subtitle()

func _show_next_subtitle():
	if subtitle_queue.is_empty():
		subtitle_box.visible = false
		return
	var sub = subtitle_queue.pop_front()
	subtitle_box.text = sub.text
	subtitle_box.visible = true
	current_subtitle_timer = sub.duration

func _on_sfx_played(path: String, position: Vector3):
	if not audio_indicators_enabled:
		return

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return

	var dist = player.global_position.distance_to(position)
	if dist > 30.0:
		return

	# Show directional indicator
	var dir = (position - player.global_position).normalized()
	var angle = atan2(dir.x, dir.z) - player.rotation.y
	_show_direction_indicator(angle, dist)

func _show_direction_indicator(angle: float, distance: float):
	if not direction_indicator:
		return
	direction_indicator.visible = true
	direction_indicator.rotation = angle
	# Fade based on distance
	var alpha = clamp(1.0 - distance / 30.0, 0.2, 1.0)
	direction_indicator.modulate.a = alpha

	await get_tree().create_timer(2.0).timeout
	direction_indicator.visible = false

func set_subtitles_enabled(enabled: bool):
	subtitles_enabled = enabled
	if not enabled:
		subtitle_box.visible = false
		subtitle_queue.clear()

func set_audio_indicators_enabled(enabled: bool):
	audio_indicators_enabled = enabled
	if not enabled:
		audio_indicator.visible = false
		direction_indicator.visible = false
