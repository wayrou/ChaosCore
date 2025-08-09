# UIManager.gd (Godot 4.4) — Autoload as "UIManager"
extends Node

@export var debug: bool = true
@export_file("*.tscn") var pause_menu_path: String = "res://ui/PauseMenu.tscn"
@export_file("*.tscn") var game_menu_path:  String = "res://ui/InGameMenu.tscn"

var _pause_menu: Node
var _game_menu: Node
var _debounce_t := 0.0
var _last_action_frame := -1

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if debug: print("[UI] READY")
	_ensure_menus()

func _input(e: InputEvent) -> void:
	if e is InputEventKey and (e as InputEventKey).echo: return
	var f := Engine.get_frames_drawn()
	if _last_action_frame == f: return

	if e.is_action_pressed("pause"):
		if debug: print("[UI] _input pause")
		_last_action_frame = f; _debounce_t = 0.18
		toggle_pause_menu(); get_viewport().set_input_as_handled()
	elif e.is_action_pressed("menu"):
		if debug: print("[UI] _input menu")
		_last_action_frame = f; _debounce_t = 0.18
		toggle_game_menu(); get_viewport().set_input_as_handled()

func _process(dt: float) -> void:
	if _debounce_t > 0.0: _debounce_t -= dt

func _ensure_menus() -> void:
	if _pause_menu == null:
		_pause_menu = _instance_menu(pause_menu_path, "PauseMenu")
		_set_visible(_pause_menu, false)
	if _game_menu == null:
		_game_menu = _instance_menu(game_menu_path, "InGameMenu")
		_set_visible(_game_menu, false)

func _instance_menu(path: String, label: String) -> Node:
	var inst: Node = null
	if path != "" and ResourceLoader.exists(path):
		var ps := load(path) as PackedScene
		if ps != null:
			inst = ps.instantiate()
			if debug: print("[UI] loaded ", label, " from ", path)
	if inst == null:
		# minimal fallback overlay so you still see something if paths are wrong
		var cl := CanvasLayer.new(); cl.layer = 400
		var root := Control.new(); root.set_anchors_preset(Control.PRESET_FULL_RECT)
		var bg := ColorRect.new(); bg.color = Color(0,0,0,0.7); bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		var lbl := Label.new(); lbl.text = "[ " + label.to_upper() + " ]"; lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
		var sys := SystemFont.new(); sys.font_names = ["Cascadia Mono","Consolas","JetBrains Mono","DejaVu Sans Mono","Noto Sans Mono","monospace"]
		var ls := LabelSettings.new(); ls.font = sys; ls.font_size = 48; ls.font_color = Color(0.0,1.0,0.7); ls.outline_size = 2; ls.outline_color = Color(0,0,0,0.95)
		lbl.label_settings = ls; lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		root.add_child(bg); root.add_child(lbl); cl.add_child(root)
		inst = cl
		if debug: push_warning("[UI] Using TEMP overlay for " + label)
	add_child(inst)                       # ← add under UIManager (so you can expand it)
	inst.process_mode = Node.PROCESS_MODE_ALWAYS
	return inst

func toggle_pause_menu() -> void:
	_ensure_menus()
	if _is_visible(_game_menu): _set_visible(_game_menu, false)
	var show := not _is_visible(_pause_menu)
	if debug: print("[UI] pause -> ", show)
	_set_visible(_pause_menu, show)
	_apply_paused_state(show)
	if debug: _debug_dump()

func toggle_game_menu() -> void:
	_ensure_menus()
	if _is_visible(_pause_menu):
		_set_visible(_pause_menu, false)
		_apply_paused_state(false)
	var show := not _is_visible(_game_menu)
	if debug: print("[UI] menu -> ", show)
	_set_visible(_game_menu, show)
	_apply_paused_state(show)
	if debug: _debug_dump()

func close_all() -> void:
	_ensure_menus()
	_set_visible(_pause_menu, false)
	_set_visible(_game_menu, false)
	_apply_paused_state(false)

func _apply_paused_state(want_paused: bool) -> void:
	get_tree().paused = want_paused
	if _pause_menu: _pause_menu.process_mode = Node.PROCESS_MODE_ALWAYS
	if _game_menu:  _game_menu.process_mode  = Node.PROCESS_MODE_ALWAYS

# -------- visibility helpers --------
func _set_visible(n: Node, v: bool) -> void:
	if n == null: return
	if n is CanvasLayer:
		(n as CanvasLayer).visible = v; return
	if n is CanvasItem:
		(n as CanvasItem).visible = v; return
	var c := n.get_node_or_null("Root")
	if c is CanvasItem:
		(c as CanvasItem).visible = v

func _is_visible(n: Node) -> bool:
	if n == null: return false
	if n is CanvasLayer: return (n as CanvasLayer).visible
	if n is CanvasItem:  return (n as CanvasItem).visible
	var c := n.get_node_or_null("Root")
	if c is CanvasItem: return (c as CanvasItem).visible
	return false

func _debug_dump() -> void:
	if not debug: return
	print("[UI] paths:",
		" pause=", (_pause_menu and _pause_menu.get_path()) or "<nil>",
		" game=",  (_game_menu  and _game_menu.get_path()) or "<nil>")
	print("[UI] visible: pause=", _is_visible(_pause_menu), " game=", _is_visible(_game_menu))
