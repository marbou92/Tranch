extends Control

@onready var cause_label = $VBoxContainer/CauseLabel
@onready var continue_button = $VBoxContainer/ContinueButton

var death_causes: Dictionary = {
	"janitor": "The Janitor found you.",
	"crawler": "Something grabbed you from the dark.",
	"teacher": "She heard you.",
	"sanity": "Your mind could not take any more.",
	"default": "You did not survive the night.",
}

func _ready():
	visible = false
	continue_button.pressed.connect(_on_continue)
	EventBus.death_screen_show.connect(_show)
	EventBus.death_screen_hide.connect(_hide)

func _show(cause: String = ""):
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var text = death_causes.get(cause, death_causes["default"])
	cause_label.text = text
	# Black fade in
	$AnimationPlayer.play("fade_in")

func _hide():
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_continue():
	EventBus.death_screen_hide.emit()
	GameState.resume_game()
	# Reload from last save or checkpoint
	if SaveManager.has_save(0):
		SaveManager.load_game(0)
	else:
		get_tree().reload_current_scene()
