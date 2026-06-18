extends PuzzleBase

@export var digit_from_main: int = 0
@export var digit_from_science: int = 0
@export var digit_from_gym: int = 0
@export var digit_from_cafe: int = 0

var entered_code: String = ""

func _ready():
	super._ready()
	puzzle_id = "courtyard_gate"
	code_length = 4

func get_correct_code() -> String:
	return str(digit_from_main) + str(digit_from_science) + str(digit_from_gym) + str(digit_from_cafe)

func enter_digit(digit: int):
	if entered_code.length() < 4:
		entered_code += str(digit)
		EventBus.play_sfx.emit("res://audio/sfx/dial_click.ogg", global_position)

	if entered_code.length() == 4:
		check_code()

func check_code():
	if entered_code == get_correct_code():
		solve()
		open_gate()
	else:
		fail()
		entered_code = ""

func open_gate():
	EventBus.play_sfx.emit("res://audio/sfx/gate_open.ogg", global_position)
	# Enable transition to exterior
