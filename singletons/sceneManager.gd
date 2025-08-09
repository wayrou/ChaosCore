# SceneManager.gd (Godot 4.4)
# Add as Autoload named "SceneManager" (Project Settings → Autoload).
extends Node

@export var fade_time: float = 0.25
@export var fade_color: Color = Color(0, 0, 0, 1.0)  # we'll animate alpha

var last_scene_path: String = ""
var last_spawn_name: StringName = &""

var _layer: CanvasLayer
var _fade: ColorRect

func _ready() -> void:
	print("[SceneManager] autoload READY")
	_layer = CanvasLayer.new()
	_layer.layer = 100
	add_child(_layer)

	_fade = ColorRect.new()
	_fade.color = Color(fade_color.r, fade_color.g, fade_color.b, 0.0) # start transparent
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_layer.add_child(_fade)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)

func change_scene(next_scene: String, spawn_name: StringName = &"") -> void:
	var cur := get_tree().current_scene
	if cur != null:
		last_scene_path = cur.scene_file_path
	else:
		last_scene_path = ""
	last_spawn_name = spawn_name
	print("[SceneManager] change_scene ->", next_scene, " spawn=", spawn_name)
	_do_change(next_scene, spawn_name)

func change_back() -> void:
	if last_scene_path != "":
		print("[SceneManager] change_back ->", last_scene_path, " spawn=", last_spawn_name)
		_do_change(last_scene_path, last_spawn_name)

func _do_change(next_scene: String, spawn_name: StringName) -> void:
	call_deferred("_async_change", next_scene, spawn_name)

func _async_change(next_scene: String, spawn_name: StringName) -> void:
	print("[SceneManager] _async_change start")
	await _fade_to(1.0, fade_time)

	var err := get_tree().change_scene_to_file(next_scene)
	print("[SceneManager] change_scene_to_file err=", err)
	if err != OK:
		push_error("SceneManager: change_scene_to_file failed: %s" % err)
		await _fade_to(0.0, 0.1)
		return

	# Let the new scene build and _ready() run
	await get_tree().process_frame
	await get_tree().process_frame

	var placed := _move_player_to_spawn(spawn_name)
	print("[SceneManager] placed=", placed)

	await _fade_to(0.0, fade_time)

func _move_player_to_spawn(spawn_name: StringName) -> bool:
	print("[SceneManager] _move_player_to_spawn spawn=", spawn_name)
	if String(spawn_name).is_empty():
		print("[SceneManager] spawn_name empty")
		return false

	var player := get_tree().get_first_node_in_group("player") as Node2D
	print("[SceneManager] player=", player)
	if player == null:
		push_warning("SceneManager: no node in group 'player' found.")
		return false

	var marker := _find_spawn_marker(spawn_name)
	print("[SceneManager] marker=", marker)
	if marker == null:
		push_warning("SceneManager: spawn marker '%s' NOT found." % String(spawn_name))
		_debug_list_spawn_points()
		return false

	player.global_position = marker.global_position
	return true

func _find_spawn_marker(spawn_name: StringName) -> Node2D:
	var root := get_tree().current_scene
	if root == null:
		return null

	var target := String(spawn_name)
	var target_lc := target.to_lower()

	# Preferred: SpawnPoints/<Name>
	var sp := root.get_node_or_null("SpawnPoints")
	if sp:
		var m := sp.get_node_or_null(target)
		if m is Node2D:
			return m as Node2D
		# Case-insensitive fallback within SpawnPoints
		for c in sp.get_children():
			if c is Node2D and c.name.to_lower() == target_lc:
				return c as Node2D

	# Group-based fallback (NOTE: use SceneTree here)
	for n in get_tree().get_nodes_in_group("spawn_point"):
		if n is Node2D and (n.name == target or n.name.to_lower() == target_lc):
			return n as Node2D

	# Last resort: deep name search
	var any := root.find_child(target, true, false)
	if any is Node2D:
		return any as Node2D

	return null

func _debug_list_spawn_points() -> void:
	var root := get_tree().current_scene
	if root == null: return
	var names: Array[String] = []
	var sp := root.get_node_or_null("SpawnPoints")
	if sp:
		for c in sp.get_children():
			if c is Node2D:
				names.append(c.name)
	print("SceneManager DEBUG: SpawnPoints children =", names)

	var gnames: Array[String] = []
	for n in get_tree().get_nodes_in_group("spawn_point"):
		if n is Node2D:
			gnames.append(n.name)
	print("SceneManager DEBUG: group 'spawn_point' =", gnames)

func _fade_to(alpha: float, time_sec: float) -> void:
	var tw := create_tween()
	tw.tween_property(_fade, "color:a", alpha, time_sec)
	await tw.finished
