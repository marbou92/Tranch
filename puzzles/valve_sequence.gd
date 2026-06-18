extends PuzzleBase

@export var correct_sequence: Array = [1, 3, 2]  # Valve indices in order
@export var num_valves: int = 3

var activated_valves: Array = []
var all_valves_open: bool = false


func activate_valve(valve_index: int):
	if is_solved:
		return
	if valve_index in activated_valves:
		return

	activated_valves.append(valve_index)
	EventBus.play_sfx.emit("res://audio/sfx/valve_turn.ogg", global_position)

	# Check if sequence is correct so far
	var pos = activated_valves.size() - 1
	if activated_valves[pos] != correct_sequence[pos]:
		reset_sequence()
		fail()
		return

	if activated_valves.size() == correct_sequence.size():
		solve()
		all_valves_open = true


func reset_sequence():
	activated_valves.clear()
	all_valves_open = false
	EventBus.play_sfx.emit("res://audio/sfx/valve_reset.ogg", global_position)
