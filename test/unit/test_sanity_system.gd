# GUT unit test — sanity system drain rates and thresholds
# Run: godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit
extends GutTest

var SanitySystemAutoload: Node


func before_all():
	# The SanitySystem autoload is created by Godot at startup. We grab it here
	# so each test can reset it cleanly.
	SanitySystemAutoload = SanitySystem


func before_each():
	# Reset sanity to full before every test
	SanitySystemAutoload.sanity = 100.0
	SanitySystemAutoload.is_in_safe_room = false
	SanitySystemAutoload.input_loss_timer = 0.0
	SanitySystemAutoload.hallucination_cooldown = 0.0


func test_sanity_starts_at_100():
	assert_eq(SanitySystemAutoload.sanity, 100.0, "Sanity should initialise to 100")


func test_drain_dark_reduces_sanity():
	var start_sanity := SanitySystemAutoload.sanity
	SanitySystemAutoload.drain_dark(1.0)  # 1 second of dark drain
	assert_lt(SanitySystemAutoload.sanity, start_sanity, "Sanity should drop in the dark")
	# DRAIN_DARK = 0.4/sec, so 1.0s of drain → −0.4
	assert_almost_eq(SanitySystemAutoload.sanity, start_sanity - 0.4, 0.001, "Drain amount should match DRAIN_DARK constant")


func test_drain_dark_blocked_in_safe_room():
	SanitySystemAutoload.set_safe_room(true)
	var start_sanity := SanitySystemAutoload.sanity
	SanitySystemAutoload.drain_dark(1.0)
	assert_eq(SanitySystemAutoload.sanity, start_sanity, "Sanity should NOT drain in safe room")


func test_drain_entity_rate_matches_gdd():
	# GDD §4.1: entity drain is the strongest drain source
	var start_sanity := SanitySystemAutoload.sanity
	SanitySystemAutoload.drain_entity(1.0)
	# DRAIN_ENTITY = 1.8/sec
	assert_almost_eq(SanitySystemAutoload.sanity, start_sanity - 1.8, 0.001, "Entity drain must match GDD §4.1")


func test_drain_entity_clamps_at_zero():
	SanitySystemAutoload.sanity = 0.5
	SanitySystemAutoload.drain_entity(10.0)
	assert_eq(SanitySystemAutoload.sanity, 0.0, "Sanity must clamp at 0, never go negative")


func test_use_medicine_restores_25():
	SanitySystemAutoload.sanity = 50.0
	SanitySystemAutoload.use_medicine()
	# RESTORE_MEDICINE = 25.0
	assert_eq(SanitySystemAutoload.sanity, 75.0, "Medicine should restore exactly 25 sanity (GDD §4 inventory)")


func test_use_medicine_clamps_at_100():
	SanitySystemAutoload.sanity = 90.0
	SanitySystemAutoload.use_medicine()
	assert_eq(SanitySystemAutoload.sanity, 100.0, "Medicine must not exceed 100 sanity")


func test_get_sanity_state_returns_correct_tier():
	# GDD §4.1 sanity tiers
	var cases := {
		100.0: "normal",
		75.0: "normal",
		74.0: "mild",
		50.0: "mild",
		49.0: "moderate",
		25.0: "moderate",
		24.0: "severe",
		10.0: "severe",
		9.0: "critical",
		0.0: "critical",
	}
	for sanity_value in cases:
		SanitySystemAutoload.sanity = sanity_value
		var expected: String = cases[sanity_value]
		assert_eq(SanitySystemAutoload.get_sanity_state(), expected,
			"Sanity %s should map to state '%s'" % [sanity_value, expected])


func test_threshold_signal_emitted_when_crossing_50():
	# GDD §4.1: 50 is the "soft heartbeat" threshold
	SanitySystemAutoload._previous_threshold = 100.0
	var signal_fired := false
	SanitySystemAutoload.sanity_threshold_crossed.connect(
		func(threshold: float):
			if threshold == 50.0:
				signal_fired = true
	)
	SanitySystemAutoload.sanity = 49.0  # cross the 50 boundary
	SanitySystemAutoload._check_thresholds()
	assert_true(signal_fired, "Crossing 50 sanity should emit sanity_threshold_crossed(50.0)")
