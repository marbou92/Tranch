extends PuzzleBase

@export var correct_configuration: Dictionary = {
	"circuit_a": true,
	"circuit_b": false,
	"circuit_c": true,
	"circuit_d": true,
}

var current_configuration: Dictionary = {
	"circuit_a": false,
	"circuit_b": false,
	"circuit_c": false,
	"circuit_d": false,
}


func toggle_circuit(circuit_id: String):
	if current_configuration.has(circuit_id):
		current_configuration[circuit_id] = !current_configuration[circuit_id]
		EventBus.play_sfx.emit("res://audio/sfx/fuse_toggle.ogg", global_position)
		check_configuration()


func check_configuration():
	var is_correct = true
	for circuit in correct_configuration:
		if current_configuration.get(circuit, false) != correct_configuration[circuit]:
			is_correct = false
			break

	if is_correct:
		solve()
		_restore_circuits()


func _restore_circuits():
	EventBus.play_sfx.emit("res://audio/sfx/power_hum.ogg", global_position)
