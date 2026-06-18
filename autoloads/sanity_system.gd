extends Node

signal sanity_changed(value: float)
signal sanity_threshold_crossed(threshold: float)
signal hallucination_triggered
signal blackout_triggered

var sanity: float = 100.0
var is_in_safe_room: bool = false
var input_loss_timer: float = 0.0
var hallucination_cooldown: float = 0.0

const DRAIN_DARK = 0.4
const DRAIN_ENTITY = 1.8
const RESTORE_LIGHT = 0.6
const RESTORE_SAFE = 1.2
const RESTORE_MEDICINE = 25.0
const HALLUCINATION_COOLDOWN = 10.0

var _previous_threshold: float = 100.0


func _process(delta):
	_apply_drain(delta)
	_apply_effects()
	_check_thresholds()
	sanity_changed.emit(sanity)

	if hallucination_cooldown > 0:
		hallucination_cooldown -= delta


func _apply_drain(delta):
	if is_in_safe_room:
		sanity = min(100, sanity + RESTORE_SAFE * delta)
		return
	# Dark drain is handled by player controller
	# Entity drain is called externally


func drain_entity(delta):
	sanity = max(0, sanity - DRAIN_ENTITY * delta)
	if sanity <= 0:
		blackout_triggered.emit()


func drain_dark(delta):
	if not is_in_safe_room:
		sanity = max(0, sanity - DRAIN_DARK * delta)


func restore_light(delta):
	sanity = min(100, sanity + RESTORE_LIGHT * delta)


func restore_safe(delta):
	if is_in_safe_room:
		sanity = min(100, sanity + RESTORE_SAFE * delta)


func use_medicine():
	sanity = min(100, sanity + RESTORE_MEDICINE)


func _apply_effects():
	var t = 1.0 - (sanity / 100.0)

	# Update sanity overlay shader
	var overlay = get_node_or_null("/root/Main/HUD/SanityOverlay")
	if overlay and overlay.material:
		overlay.material.set_shader_parameter("vignette_intensity", t * 0.8)
		overlay.material.set_shader_parameter("distort_strength", t * t * 0.06)
		overlay.material.set_shader_parameter("chromatic_aberration", t * 0.015)

	# Heartbeat audio
	var heartbeat = get_node_or_null("/root/Main/HeartbeatPlayer")
	if heartbeat:
		var hb_vol = -40.0 + (t * 35.0)
		heartbeat.volume_db = hb_vol
		if sanity < 50 and not heartbeat.playing:
			heartbeat.play()
		elif sanity >= 50:
			heartbeat.stop()

	# Whisper audio
	var whispers = get_node_or_null("/root/Main/WhisperPlayer")
	if whispers:
		if sanity < 40:
			whispers.volume_db = -30.0 + ((0.4 - sanity / 100.0) * 50)
			if not whispers.playing:
				whispers.play()
		else:
			if whispers.playing:
				whispers.stop()

	# Hallucination trigger at very low sanity
	if sanity < 10 and hallucination_cooldown <= 0 and randf() < 0.002:
		hallucination_triggered.emit()
		hallucination_cooldown = HALLUCINATION_COOLDOWN

	# Input loss at critical sanity
	if sanity < 9:
		input_loss_timer = 2.0


func _check_thresholds():
	var thresholds = [75.0, 50.0, 25.0, 10.0]
	for threshold in thresholds:
		if sanity <= threshold and _previous_threshold > threshold:
			sanity_threshold_crossed.emit(threshold)
	_previous_threshold = sanity


func set_safe_room(in_safe: bool):
	is_in_safe_room = in_safe


func get_sanity_state() -> String:
	if sanity >= 75:
		return "normal"
	elif sanity >= 50:
		return "mild"
	elif sanity >= 25:
		return "moderate"
	elif sanity >= 10:
		return "severe"
	else:
		return "critical"


func is_input_lost() -> bool:
	return input_loss_timer > 0


func _process_input_loss(delta):
	if input_loss_timer > 0:
		input_loss_timer -= delta
