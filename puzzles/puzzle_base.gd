extends Node3D
class_name PuzzleBase

@export var puzzle_id: String = ""
@export var puzzle_name: String = ""
@export var zone_id: String = ""
@export var is_solved: bool = false
@export var is_multi_step: bool = false
@export var required_items: Array = []
# Length of code for combination-style puzzles (used by courtyard_gate,
# combination_lock, etc.). Default 0 = not a code puzzle.
@export var code_length: int = 0

signal puzzle_started(puzzle_id: String)
signal puzzle_solved(puzzle_id: String)
signal puzzle_failed(puzzle_id: String)
signal puzzle_progress(puzzle_id: String, step: int)


func _ready():
	add_to_group("puzzles")


func start_puzzle():
	if is_solved:
		return
	puzzle_started.emit(puzzle_id)
	EventBus.puzzle_started.emit(puzzle_id)
	GameState.solve_puzzle(puzzle_id)


func solve():
	is_solved = true
	puzzle_solved.emit(puzzle_id)
	EventBus.puzzle_solved.emit(puzzle_id)


func fail():
	puzzle_failed.emit(puzzle_id)
	EventBus.puzzle_failed.emit(puzzle_id)


func check_requirements() -> bool:
	return true


func reset():
	is_solved = false
