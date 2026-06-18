extends Control

@onready var master_slider = $VBoxContainer/SettingsTabs/Audio/MasterSlider
@onready var music_slider = $VBoxContainer/SettingsTabs/Audio/MusicSlider
@onready var sfx_slider = $VBoxContainer/SettingsTabs/Audio/SFXSlider
@onready var ambient_slider = $VBoxContainer/SettingsTabs/Audio/AmbientSlider

@onready var mouse_sens_slider = $VBoxContainer/SettingsTabs/Controls/MouseSensSlider
@onready var invert_y_check = $VBoxContainer/SettingsTabs/Controls/InvertYCheck
@onready var fov_slider = $VBoxContainer/SettingsTabs/Controls/FOVSlider

@onready var graphics_tier_option = $VBoxContainer/SettingsTabs/Graphics/GraphicsTierOption
@onready var vsync_check = $VBoxContainer/SettingsTabs/Graphics/VSyncCheck
@onready var fps_cap_option = $VBoxContainer/SettingsTabs/Graphics/FPSCapOption

@onready var subtitles_check = $VBoxContainer/SettingsTabs/Accessibility/SubtitlesCheck
@onready var audio_indicators_check = $VBoxContainer/SettingsTabs/Accessibility/AudioIndicatorsCheck
@onready var colorblind_option = $VBoxContainer/SettingsTabs/Accessibility/ColorblindOption
@onready var text_size_option = $VBoxContainer/SettingsTabs/Accessibility/TextSizeOption
@onready var permadeath_check = $VBoxContainer/SettingsTabs/Accessibility/PermadeathCheck

@onready var back_button = $VBoxContainer/BackButton

var settings: Dictionary = {}


func _ready():
	_load_settings()
	_connect_signals()
	_apply_to_ui()


func _connect_signals():
	master_slider.value_changed.connect(_on_master_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	ambient_slider.value_changed.connect(_on_ambient_volume_changed)
	mouse_sens_slider.value_changed.connect(_on_mouse_sens_changed)
	invert_y_check.toggled.connect(_on_invert_y_changed)
	fov_slider.value_changed.connect(_on_fov_changed)
	graphics_tier_option.item_selected.connect(_on_graphics_tier_changed)
	vsync_check.toggled.connect(_on_vsync_changed)
	fps_cap_option.item_selected.connect(_on_fps_cap_changed)
	subtitles_check.toggled.connect(_on_subtitles_changed)
	audio_indicators_check.toggled.connect(_on_audio_indicators_changed)
	colorblind_option.item_selected.connect(_on_colorblind_changed)
	text_size_option.item_selected.connect(_on_text_size_changed)
	permadeath_check.toggled.connect(_on_permadeath_changed)
	back_button.pressed.connect(_on_back)


func _load_settings():
	var file = FileAccess.open("user://settings.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		json.parse(file.get_as_text())
		file.close()
		settings = json.data
	else:
		settings = _default_settings()


func _default_settings() -> Dictionary:
	return {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"ambient_volume": 0.7,
		"mouse_sensitivity": 0.2,
		"invert_y": false,
		"fov": 75,
		"graphics_tier": -1,  # Auto
		"vsync": true,
		"fps_cap": 0,
		"subtitles": true,
		"audio_indicators": false,
		"colorblind_mode": 0,
		"text_size": 1,
		"permadeath": false,
	}


func _save_settings():
	var file = FileAccess.open("user://settings.json", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(settings, "\t"))
		file.close()


func _apply_to_ui():
	master_slider.value = settings.get("master_volume", 1.0)
	music_slider.value = settings.get("music_volume", 0.8)
	sfx_slider.value = settings.get("sfx_volume", 1.0)
	ambient_slider.value = settings.get("ambient_volume", 0.7)
	mouse_sens_slider.value = settings.get("mouse_sensitivity", 0.2)
	invert_y_check.button_pressed = settings.get("invert_y", false)
	fov_slider.value = settings.get("fov", 75)
	graphics_tier_option.selected = settings.get("graphics_tier", -1) + 1
	vsync_check.button_pressed = settings.get("vsync", true)
	fps_cap_option.selected = settings.get("fps_cap", 0)
	subtitles_check.button_pressed = settings.get("subtitles", true)
	audio_indicators_check.button_pressed = settings.get("audio_indicators", false)
	colorblind_option.selected = settings.get("colorblind_mode", 0)
	text_size_option.selected = settings.get("text_size", 1)
	permadeath_check.button_pressed = settings.get("permadeath", false)


func _on_master_volume_changed(value):
	settings.master_volume = value
	AudioServer.set_bus_volume_db(0, linear_to_db(value))
	_save_settings()


func _on_music_volume_changed(value):
	settings.music_volume = value
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	_save_settings()


func _on_sfx_volume_changed(value):
	settings.sfx_volume = value
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	_save_settings()


func _on_ambient_volume_changed(value):
	settings.ambient_volume = value
	var bus_idx = AudioServer.get_bus_index("Ambient")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	_save_settings()


func _on_mouse_sens_changed(value):
	settings.mouse_sensitivity = value
	_save_settings()


func _on_invert_y_changed(pressed):
	settings.invert_y = pressed
	_save_settings()


func _on_fov_changed(value):
	settings.fov = int(value)
	var player = get_tree().get_first_node_in_group("player")
	if player and player.has_node("Camera3D"):
		player.camera.fov = value
	_save_settings()


func _on_graphics_tier_changed(index):
	var tier = index - 1  # -1 = auto, 0 = low, 1 = medium, 2 = high
	settings.graphics_tier = tier
	if tier >= 0:
		GraphicsTierManager.apply_tier(tier as GraphicsTierManager.Tier)
	_save_settings()


func _on_vsync_changed(pressed):
	settings.vsync = pressed
	if pressed:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	_save_settings()


func _on_fps_cap_changed(index):
	settings.fps_cap = index
	match index:
		0:
			Engine.max_fps = 0
		1:
			Engine.max_fps = 30
		2:
			Engine.max_fps = 60
		3:
			Engine.max_fps = 120
		4:
			Engine.max_fps = 144
	_save_settings()


func _on_subtitles_changed(pressed):
	settings.subtitles = pressed
	_save_settings()


func _on_audio_indicators_changed(pressed):
	settings.audio_indicators = pressed
	_save_settings()


func _on_colorblind_changed(index):
	settings.colorblind_mode = index
	# Apply colorblind filter
	_save_settings()


func _on_text_size_changed(index):
	settings.text_size = index
	# Apply text size scaling
	_save_settings()


func _on_permadeath_changed(pressed):
	settings.permadeath = pressed
	GameState.permadeath_enabled = pressed
	_save_settings()


func _on_back():
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
