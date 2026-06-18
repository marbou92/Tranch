extends Node

# Player signals
signal player_noise_emitted(radius: float, origin: Vector3)
signal player_sanity_changed(value: float)
signal player_flashlight_toggled(state: bool)
signal player_caught
signal player_died(cause: String)

# Enemy signals
signal enemy_alerted(enemy_id: String, position: Vector3)
signal enemy_chase_started(enemy_id: String)
signal enemy_chase_ended(enemy_id: String)
signal enemy_catch_triggered(enemy_id: String)

# Zone signals
signal zone_entered(zone_id: String)
signal zone_exited(zone_id: String)
signal zone_transition_started(from: String, to: String)
signal zone_loaded(zone_id: String)
signal zone_unloaded(zone_id: String)

# Game state signals
signal game_paused
signal game_resumed
signal game_saved(slot: int)
signal game_loaded(slot: int)
signal game_over(ending: String)

# Sanity signals
signal sanity_changed(value: float)
signal sanity_threshold_crossed(threshold: float)
signal hallucination_triggered
signal blackout_triggered

# Inventory signals
signal item_picked_up(item_id: String, slot: int)
signal item_dropped(item_id: String, slot: int)
signal item_used(item_id: String, slot: int)
signal inventory_opened
signal inventory_closed

# Puzzle signals
signal puzzle_started(puzzle_id: String)
signal puzzle_solved(puzzle_id: String)
signal puzzle_failed(puzzle_id: String)

# UI signals
signal interaction_hint_show(text: String)
signal interaction_hint_hide
signal death_screen_show(cause: String)
signal death_screen_hide

# Audio signals
signal music_state_changed(state: String)
signal ambient_changed(zone_id: String)
signal play_sfx(path: String, position: Vector3)

# Lore signals
signal lore_note_found(note_id: String)
signal journal_opened
signal journal_closed
