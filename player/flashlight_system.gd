extends Node3D

signal battery_changed(value: float)
signal flashlight_out

const MAX_BATTERY = 100.0
const DRAIN_FULL = 1.5
const DRAIN_DIM = 0.6
const BATTERY_PICKUP_VALUE = 35.0

var battery: float = MAX_BATTERY
var is_on: bool = false
var is_dim: bool = false

@onready var light_node: SpotLight3D = get_node_or_null("../Camera3D/FlashlightSpotLight3D")


func _ready():
	battery = MAX_BATTERY


func toggle():
	if battery <= 0:
		return
	is_on = !is_on
	if light_node:
		light_node.visible = is_on
	_update_mode()


func set_dim(dim: bool):
	is_dim = dim
	_update_mode()


func _update_mode():
	if not light_node:
		return
	if is_dim:
		light_node.spot_angle = 25.0
		light_node.light_energy = 2.0
	else:
		light_node.spot_angle = 45.0
		light_node.light_energy = 4.0


func drain(delta: float):
	if not is_on:
		return
	var rate = DRAIN_DIM if is_dim else DRAIN_FULL
	battery = max(0, battery - rate * delta)
	battery_changed.emit(battery)
	if battery <= 0:
		is_on = false
		if light_node:
			light_node.visible = false
		flashlight_out.emit()


func add_battery(amount: float = BATTERY_PICKUP_VALUE):
	battery = min(MAX_BATTERY, battery + amount)
	battery_changed.emit(battery)


func get_battery_percent() -> float:
	return battery / MAX_BATTERY * 100.0
