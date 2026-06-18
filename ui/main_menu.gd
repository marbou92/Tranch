extends Control

@onready var play_button = $VBoxContainer/PlayButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var quit_button = $VBoxContainer/QuitButton
@onready var version_label = $VersionLabel

func _ready():
	play_button.pressed.connect(_on_play)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)
	version_label.text = "v%s" % ProjectSettings.get_setting("application/config/version")
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _on_play():
	get_tree().change_scene_to_file("res://scenes/main.tscn")
	GameState.start_game()

func _on_settings():
	get_tree().change_scene_to_file("res://ui/settings_menu.tscn")

func _on_quit():
	get_tree().quit()
