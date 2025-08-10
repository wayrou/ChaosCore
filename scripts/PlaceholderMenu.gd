extends Control

@onready var title_label: Label = %Title

func set_title(t: String) -> void:
	title_label.text = t

func _ready() -> void:
	# So it still works when the tree is paused.
	process_mode = Node.PROCESS_MODE_ALWAYS
	title_label.grab_focus()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("attackFreeMove") or event.is_action_pressed("pause"):
		get_tree().paused = false
		queue_free()
