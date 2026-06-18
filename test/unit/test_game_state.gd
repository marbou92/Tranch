# GUT unit test — game state phase machine and progression tracking
extends GutTest


func before_each():
	# Reset GameState to a clean new-game state
	GameState.current_phase = GameState.GamePhase.MENU
	GameState.play_time = 0.0
	GameState.death_count = 0
	GameState.lore_collected.clear()
	GameState.puzzles_solved.clear()
	GameState.key_fragments = 0
	GameState.endings_seen.clear()
	GameState.is_new_game_plus = false
	GameState.permadeath_enabled = false


func test_initial_phase_is_menu():
	assert_eq(GameState.current_phase, GameState.GamePhase.MENU, "Game should start in MENU phase")


func test_start_game_transitions_to_playing():
	GameState.start_game()
	assert_eq(
		GameState.current_phase,
		GameState.GamePhase.PLAYING,
		"start_game() should transition to PLAYING"
	)


func test_pause_resume_round_trip():
	GameState.start_game()
	GameState.pause_game()
	assert_eq(GameState.current_phase, GameState.GamePhase.PAUSED)
	# get_tree().paused won't actually flip in headless test mode, but the
	# phase enum must still update
	GameState.resume_game()
	assert_eq(GameState.current_phase, GameState.GamePhase.PLAYING)


func test_player_died_increments_death_count():
	GameState.start_game()
	var deaths_before: int = GameState.death_count
	GameState.player_died("janitor")
	assert_eq(
		GameState.death_count, deaths_before + 1, "Death count must increment on player_died()"
	)
	assert_eq(GameState.current_phase, GameState.GamePhase.DEAD)


func test_add_lore_deduplicates():
	GameState.add_lore("note_001")
	GameState.add_lore("note_001")  # duplicate — should be ignored
	GameState.add_lore("note_002")
	assert_eq(GameState.lore_collected.size(), 2, "Lore collection must deduplicate by id")


func test_solve_puzzle_deduplicates():
	GameState.solve_puzzle("principal_combo")
	GameState.solve_puzzle("principal_combo")
	assert_eq(GameState.puzzles_solved.size(), 1, "Puzzle solves must deduplicate by id")


func test_key_fragments_drive_acts():
	# GDD §2 narrative: Act 1 (0 fragments), Act 2 (1–3), Act 3 (4+)
	assert_true(GameState.is_act_one(), "0 fragments = Act 1")
	GameState.add_key_fragment()
	assert_true(GameState.is_act_two(), "1 fragment = Act 2")
	GameState.add_key_fragment()
	GameState.add_key_fragment()
	assert_true(GameState.is_act_two(), "3 fragments = still Act 2")
	GameState.add_key_fragment()
	assert_true(GameState.is_act_three(), "4 fragments = Act 3 (descent)")


func test_trigger_ending_records_unique_endings():
	GameState.trigger_ending("bad")
	GameState.trigger_ending("bad")  # duplicate
	GameState.trigger_ending("true")
	assert_eq(GameState.endings_seen.size(), 2, "Endings seen list must deduplicate")
	assert_eq(GameState.current_phase, GameState.GamePhase.ENDING)


func test_play_time_format():
	GameState.play_time = 3661.0  # 1h 1m 1s
	var time_str: String = GameState.get_play_time_string()
	assert_eq(time_str, "01:01:01", "Play time string must be HH:MM:SS zero-padded")
