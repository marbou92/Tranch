extends Control

@onready var notes_list = $HBoxContainer/NotesList
@onready var note_display = $HBoxContainer/NoteDisplay

var notes: Array = []
var selected_note: int = -1


func _ready():
	visible = false
	EventBus.journal_opened.connect(_open)
	EventBus.journal_closed.connect(_close)
	EventBus.lore_note_found.connect(_on_note_found)


func _unhandled_input(event):
	if event.is_action_pressed("toggle_journal"):
		if visible:
			_close()
		else:
			_open()


func _open():
	visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_refresh_list()
	EventBus.journal_opened.emit()


func _close():
	visible = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	EventBus.journal_closed.emit()


func _on_note_found(note_id: String):
	_refresh_list()


func _refresh_list():
	for child in notes_list.get_children():
		child.queue_free()

	for note_id in GameState.lore_collected:
		var btn = Button.new()
		btn.text = note_id
		btn.pressed.connect(_on_note_selected.bind(note_id))
		notes_list.add_child(btn)


func _on_note_selected(note_id: String):
	# Load and display note content from data
	var data = _load_note_data(note_id)
	if note_display:
		note_display.text = data.get("content", "Illegible text...")


func _load_note_data(note_id: String) -> Dictionary:
	var file = FileAccess.open("res://data/lore_notes.json", FileAccess.READ)
	if file:
		var json = JSON.new()
		json.parse(file.get_as_text())
		file.close()
		var notes_data = json.data
		if notes_data is Array:
			for note in notes_data:
				if note.get("id", "") == note_id:
					return note
	return {}
