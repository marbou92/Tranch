extends Control

@onready var battery_bar = $MarginContainer/VBoxContainer/BatteryBar
@onready var interaction_label = $InteractionLabel
@onready var sanity_overlay = $SanityOverlay

var player: CharacterBody3D


func _ready():
	EventBus.interaction_hint_show.connect(_show_hint)
	EventBus.interaction_hint_hide.connect(_hide_hint)
	EventBus.player_sanity_changed.connect(_update_sanity_overlay)


func _process(_delta):
	if not player:
		player = get_tree().get_first_node_in_group("player")
		return

	# Update battery bar
	if battery_bar:
		battery_bar.value = player.flashlight_bat
		# Pulse red when low
		if player.flashlight_bat < 15:
			battery_bar.modulate = Color.RED if Engine.get_frames_drawn() % 60 < 30 else Color.WHITE
		else:
			battery_bar.modulate = Color.WHITE


func _show_hint(text: String):
	if interaction_label:
		interaction_label.text = text
		interaction_label.visible = true


func _hide_hint():
	if interaction_label:
		interaction_label.visible = false


func _update_sanity_overlay(value: float):
	if not sanity_overlay:
		return
	var t = 1.0 - (value / 100.0)
	sanity_overlay.material.set_shader_parameter("vignette_intensity", t * 0.8)
	sanity_overlay.material.set_shader_parameter("distort_strength", t * t * 0.06)
	sanity_overlay.material.set_shader_parameter("chromatic_aberration", t * 0.015)
	sanity_overlay.visible = value < 75
