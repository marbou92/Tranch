extends CanvasLayer

@onready var move_joystick = $MoveJoystick
@onready var look_area = $LookArea
@onready var flashlight_btn = $ActionButtonCluster/FlashlightBtn
@onready var crouch_btn = $ActionButtonCluster/CrouchBtn
@onready var interact_btn = $InteractBtn
@onready var journal_btn = $TopBar/JournalBtn
@onready var pause_btn = $TopBar/PauseBtn
@onready var inventory_btn = $InventoryBtn

var move_input: Vector2 = Vector2.ZERO
var look_delta: Vector2 = Vector2.ZERO
var is_sprinting: bool = false
var last_tap_time: float = 0.0
var gyro_enabled: bool = false

var player: CharacterBody3D

func _ready():
	visible = OS.has_feature("android") or OS.has_feature("ios")
	if not visible:
		return
	
	# Connect signals
	flashlight_btn.pressed.connect(_on_flashlight)
	crouch_btn.pressed.connect(_on_crouch)
	journal_btn.pressed.connect(_on_journal)
	pause_btn.pressed.connect(_on_pause)
	inventory_btn.pressed.connect(_on_inventory)
	
	# Check gyroscope
	if Input.get_gyroscope() != Vector3.ZERO:
		gyro_enabled = true

func _process(_delta):
	if not visible or not player:
		player = get_tree().get_first_node_in_group("player")
		return
	
	# Apply movement input
	var input = Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_forward", "move_back")
	)
	# On mobile, joystick provides this directly

func _input(event):
	if not visible:
		return
	
	# Handle look area swipe
	if event is InputEventScreenTouch and event.is_pressed():
		var touch_pos = event.position
		var screen_width = DisplayServer.screen_get_size().x
		# Right 60% of screen is look area
		if touch_pos.x > screen_width * 0.4:
			look_delta = Vector2.ZERO
	
	if event is InputEventScreenDrag:
		var touch_pos = event.position
		var screen_width = DisplayServer.screen_get_size().x
		if touch_pos.x > screen_width * 0.4:
			look_delta = event.relative * 0.005
			_apply_look()
	
	# Double-tap sprint
	if event is InputEventScreenTouch and event.is_pressed():
		var now = Time.get_ticks_msec() / 1000.0
		if now - last_tap_time < 0.3:
			is_sprinting = !is_sprinting
		last_tap_time = now

func _apply_look():
	if not player:
		return
	player.rotate_y(-look_delta.x * 0.2)
	if player.has_node("Camera3D"):
		player.camera.rotate_x(-look_delta.y * 0.2)
		player.camera.rotation.x = clamp(player.camera.rotation.x, deg_to_rad(-85), deg_to_rad(85))
	look_delta = Vector2.ZERO

func _apply_gyroscope(delta):
	if not gyro_enabled or not player:
		return
	var gyro = Input.get_gyroscope()
	player.rotate_y(-gyro.y * delta)
	if player.has_node("Camera3D"):
		player.camera.rotate_x(-gyro.x * delta)

func _on_flashlight():
	Input.action_press("toggle_flashlight")

func _on_crouch():
	Input.action_press("toggle_crouch")

func _on_journal():
	Input.action_press("toggle_journal")

func _on_pause():
	Input.action_press("pause")

func _on_inventory():
	Input.action_press("toggle_inventory")

func trigger_haptic(type: String):
	if OS.has_feature("android"):
		match type:
			"jump_scare":
				Input.vibrate_handheld(100)
			"catch":
				Input.vibrate_handheld(300)
			"interaction":
				Input.vibrate_handheld(30)
	elif OS.has_feature("ios"):
		# iOS haptics via AudioServicesPlaySystemSound
		match type:
			"jump_scare":
				Input.vibrate_handheld(100)
			"catch":
				Input.vibrate_handheld(300)
			"interaction":
				Input.vibrate_handheld(30)
