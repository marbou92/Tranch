extends PuzzleBase

enum Stage { SAMPLE_ID, CHEMICAL_SEQUENCE, POWER_OVERRIDE }

@export var correct_sample_id: String = "TRN7"
@export var correct_chemical_sequence: Array = ["H2O", "NaOH", "TRN7"]
@export var correct_power_sequence: Array = [2, 1, 3]

var current_stage: Stage = Stage.SAMPLE_ID
var sample_id_input: String = ""
var chemical_inputs: Array = []
var power_inputs: Array = []
var stages_completed: int = 0


func _ready():
	super._ready()
	puzzle_id = "final_puzzle"
	is_multi_step = true


func input_sample_id(id: String):
	if current_stage != Stage.SAMPLE_ID:
		return
	sample_id_input = id
	if sample_id_input == correct_sample_id:
		advance_stage()
		puzzle_progress.emit(puzzle_id, 1)
	else:
		fail()


func input_chemical(chem: String):
	if current_stage != Stage.CHEMICAL_SEQUENCE:
		return
	chemical_inputs.append(chem)
	var pos = chemical_inputs.size() - 1
	if chemical_inputs[pos] != correct_chemical_sequence[pos]:
		chemical_inputs.clear()
		fail()
		return
	if chemical_inputs.size() == correct_chemical_sequence.size():
		advance_stage()
		puzzle_progress.emit(puzzle_id, 2)


func input_power_switch(switch_id: int):
	if current_stage != Stage.POWER_OVERRIDE:
		return
	power_inputs.append(switch_id)
	var pos = power_inputs.size() - 1
	if power_inputs[pos] != correct_power_sequence[pos]:
		power_inputs.clear()
		fail()
		return
	if power_inputs.size() == correct_power_sequence.size():
		solve()
		_trigger_endgame()


func advance_stage():
	stages_completed += 1
	current_stage = stages_completed as Stage


func _trigger_endgame():
	# Determine which ending based on player's collected items and lore
	var inv = get_node_or_null("/root/InventorySystem")
	var has_marsh_report = inv and inv.has_item("marsh_final_report")
	var has_all_lore = GameState.lore_collected.size() >= 12

	if has_all_lore and inv and inv.has_item("trn7_antidote"):
		GameState.trigger_ending("secret")
	elif has_marsh_report:
		GameState.trigger_ending("true")
	else:
		GameState.trigger_ending("bad")
