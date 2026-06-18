extends Node

var is_mobile: bool = false

func _ready():
	is_mobile = OS.has_feature("android") or OS.has_feature("ios")

func play_jump_scare():
	if not is_mobile:
		return
	Input.vibrate_handheld(100)

func play_catch():
	if not is_mobile:
		return
	Input.vibrate_handheld(300)

func play_interaction():
	if not is_mobile:
		return
	Input.vibrate_handheld(30)

func play_footstep():
	if not is_mobile:
		return
	Input.vibrate_handheld(10)

func play_door_creak():
	if not is_mobile:
		return
	Input.vibrate_handheld(50)
