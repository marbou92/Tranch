extends PuzzleBase

@export var correct_code: String = "000"
@export var lock_type: String = "combo"  # combo or padlock

var current_code: String = ""


func _ready():
	super._ready()
	code_length = 3
	current_code = ""
	for i in range(code_length):
		current_code += "0"


func input_digit(position: int, digit: int):
	if position < 0 or position >= code_length:
		return
	var digits = current_code.to_ascii_buffer()
	digits[position] = 48 + digit  # ASCII offset
	current_code = digits.get_string_from_ascii()


func try_code() -> bool:
	if current_code == correct_code:
		solve()
		_open_locked_object()
		return true
	fail()
	return false


func _open_locked_object():
	EventBus.play_sfx.emit("res://audio/sfx/lock_open.ogg", global_position)
