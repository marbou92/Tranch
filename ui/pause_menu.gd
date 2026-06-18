extends Control

@onready var resume_button = $VBoxContainer/ResumeButton
@onready var save_button = $VBoxContainer/SaveButton
@onready var settings_button = $VBoxContainer/SettingsButton
@onready var quit_button = $VBoxContainer/QuitButton


func _ready():
	visible = false
	resume_button.pressed.connect(_on_resume)
	save_button.pressed.connect(_on_save)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)
	EventBus.game_paused.connect(_show)
	EventBus.game_resumed.connect(_hide)


func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		if GameState.current_phase == GameState.GamePhase.PLAYING:
			GameState.pause_game()
		elif GameState.current_phase == GameState.GamePhase.PAUSED:
			GameState.resume_game()


func _show():
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _hide():
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_resume():
	GameState.resume_game()


func _on_save():
	SaveManager.save_game(0)


func _on_settings():
	# Show settings overlay
	pass


func _on_quit():
	GameState.current_phase = GameState.GamePhase.MENU
	get_tree().paused = false
	get_tree().change_scene_to_file("res://ui/main_menu.tscn")
