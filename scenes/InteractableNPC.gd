extends Area2D
class_name InteractableNPC

@export var menu_title: String = "Shop (placeholder)"

var _menu: Control = null

func _ready() -> void:
	# Make detection robust while debugging
	monitoring = true
	collision_layer = 0
	collision_mask = 0x7FFFFFFF
	process_mode = Node.PROCESS_MODE_ALWAYS

	if not body_entered.is_connected(_on_enter):
		body_entered.connect(_on_enter)
	if not body_exited.is_connected(_on_exit):
		body_exited.connect(_on_exit)

func _on_enter(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("set_current_interactable"):
		body.call_deferred("set_current_interactable", self)
		print("[NPC] Player entered")

func _on_exit(body: Node) -> void:
	if body.is_in_group("player") and body.has_method("set_current_interactable"):
		body.call_deferred("set_current_interactable", null)
		print("[NPC] Player exited")

func interact() -> void:
	print("[NPC] interact() called -> opening")
	_open_menu()

func _open_menu() -> void:
	var scene: Resource = load("res://ui/placeholder_menu.tscn")
	if scene is PackedScene:
		_menu = (scene as PackedScene).instantiate()
		_menu.process_mode = Node.PROCESS_MODE_ALWAYS
		if _menu is Control:
			(_menu as Control).set_anchors_preset(Control.PRESET_FULL_RECT)
		if _menu.has_method("set_title"):
			_menu.call("set_title", menu_title)
	else:
		var foo = 1

	# Add to root so it can't appear behind other UI
	get_tree().root.add_child(_menu)
	get_tree().paused = true
