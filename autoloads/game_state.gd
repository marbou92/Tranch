extends Node

enum GamePhase { MENU, PLAYING, PAUSED, CUTSCENE, DEAD, ENDING }

var current_phase: GamePhase = GamePhase.MENU
var current_zone: String = ""
var play_time: float = 0.0
var death_count: int = 0
var lore_collected: Array = []
var puzzles_solved: Array = []
var key_fragments: int = 0
var endings_seen: Array = []
var is_new_game_plus: bool = false
var permadeath_enabled: bool = false
var is_mobile: bool = false

func _ready():
	_detect_platform()

func _process(delta):
	if current_phase == GamePhase.PLAYING:
		play_time += delta

func _detect_platform():
	is_mobile = OS.has_feature("android") or OS.has_feature("ios")

func start_game():
	current_phase = GamePhase.PLAYING
	play_time = 0.0
	death_count = 0
	lore_collected.clear()
	puzzles_solved.clear()
	key_fragments = 0
	EventBus.game_resumed.emit()

func pause_game():
	if current_phase == GamePhase.PLAYING:
		current_phase = GamePhase.PAUSED
		get_tree().paused = true
		EventBus.game_paused.emit()

func resume_game():
	if current_phase == GamePhase.PAUSED:
		current_phase = GamePhase.PLAYING
		get_tree().paused = false
		EventBus.game_resumed.emit()

func player_died(cause: String = ""):
	current_phase = GamePhase.DEAD
	death_count += 1
	EventBus.player_died.emit(cause)
	EventBus.death_screen_show.emit(cause)

func trigger_ending(ending_type: String):
	current_phase = GamePhase.ENDING
	if ending_type not in endings_seen:
		endings_seen.append(ending_type)
	EventBus.game_over.emit(ending_type)

func add_lore(note_id: String):
	if note_id not in lore_collected:
		lore_collected.append(note_id)
		EventBus.lore_note_found.emit(note_id)

func solve_puzzle(puzzle_id: String):
	if puzzle_id not in puzzles_solved:
		puzzles_solved.append(puzzle_id)
		EventBus.puzzle_solved.emit(puzzle_id)

func add_key_fragment():
	key_fragments += 1

func get_play_time_string() -> String:
	var hours = int(play_time) / 3600
	var minutes = (int(play_time) % 3600) / 60
	var seconds = int(play_time) % 60
	return "%02d:%02d:%02d" % [hours, minutes, seconds]

func is_act_one() -> bool:
	return key_fragments < 1

func is_act_two() -> bool:
	return key_fragments >= 1 and key_fragments < 4

func is_act_three() -> bool:
	return key_fragments >= 4
