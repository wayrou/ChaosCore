# ExitArea.gd (Godot 4.4)
extends Area2D

@export_file("*.tscn") var next_scene: String
@export var spawn_name: StringName = &""      # must match a Marker2D name under SpawnPoints
@export var require_button: bool = false
@export var input_action: StringName = "ui_accept"
@export var debug: bool = true

var _already_warped: bool = false

func _ready() -> void:
	set_deferred("monitoring", true)
	body_entered.connect(_on_body_entered)
	if debug:
		var cs := get_node_or_null("CollisionShape2D")
		print("[ExitArea:", name, "] READY next=", next_scene,
			  " spawn=", spawn_name, " mask=", collision_mask,
			  " shape_ok=", (cs != null and not cs.disabled))

func _physics_process(_dt: float) -> void:
	if _already_warped: return
	# polling fallback (covers “started already on the tile”)
	for b in get_overlapping_bodies():
		if b.is_in_group("player"):
			if not require_button or Input.is_action_just_pressed(input_action):
				if debug: print("[ExitArea:", name, "] POLL overlap with", b.name)
				_go()
			return

func _on_body_entered(body: Node2D) -> void:
	if _already_warped: return
	if body.is_in_group("player"):
		if require_button:
			if debug: print("[ExitArea:", name, "] SIGNAL: inside; waiting for", input_action)
			return
		if debug: print("[ExitArea:", name, "] SIGNAL body_entered by", body.name)
		_go()

func _go() -> void:
	if _already_warped or not next_scene: return
	_already_warped = true
	var sm := get_node_or_null("/root/SceneManager")   # ← Autoload must be named SceneManager
	if debug:
		print("[ExitArea:", name, "] GO next=", next_scene, " spawn=", spawn_name,
			  " sceneMgr_found=", (sm != null))
	if sm:
		sm.change_scene(next_scene, spawn_name)
	else:
		get_tree().change_scene_to_file(next_scene)
