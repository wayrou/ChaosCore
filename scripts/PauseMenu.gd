# PauseMenu.gd (null-safe; no boolean short-circuit casts)
extends Control

# --- set these two in the Inspector ---
@export_node_path("Control") var backdrop_path: NodePath
@export_node_path("Control") var window_path:   NodePath

# Optional (only set if your names differ from defaults under Window)
@export_node_path("Label")        var title_path:        NodePath
@export_node_path("Button")       var resume_btn_path:   NodePath
@export_node_path("Button")       var options_btn_path:  NodePath
@export_node_path("Button")       var quit_btn_path:     NodePath
@export_node_path("VBoxContainer")var options_box_path:  NodePath
@export_node_path("HSlider")      var volume_slider_path:NodePath
@export_node_path("Label")        var tip_label_path:    NodePath

var _back: Control
var _win:  Control
var _title: Label
var _resume: Button
var _options_btn: Button
var _quit: Button
var _options: VBoxContainer
var _slider: HSlider
var _tip: Label

func _ready() -> void:
	_resolve_nodes()
	if _back == null or _win == null:
		push_error("PauseMenu: set 'backdrop_path' and 'window_path' in the Inspector (or ensure children are named Backdrop/Window). Got: back=%s win=%s" % [
			_back and _back.name, _win and _win.name])
		return

	# Layout
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_back.set_anchors_preset(Control.PRESET_FULL_RECT)
	_win.set_anchors_preset(Control.PRESET_CENTER)
	_win.custom_minimum_size = Vector2(540, 320)
	_win.size = _win.custom_minimum_size
	await get_tree().process_frame
	_center_window()

	_style()
	_wire()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _win:
		_center_window()

func _center_window() -> void:
	var vp := get_viewport_rect().size
	_win.position = (vp - _win.size) * 0.5

func _resolve_nodes() -> void:
	# Backdrop
	if backdrop_path != NodePath(""):
		_back = get_node_or_null(backdrop_path) as Control
	else:
		_back = get_node_or_null("Backdrop") as Control

	# Window
	if window_path != NodePath(""):
		_win = get_node_or_null(window_path) as Control
	else:
		_win = get_node_or_null("Window") as Control
		if _win == null:
			# fallback: first Panel under Root, else first Control not Backdrop
			for c in get_children():
				if c is Panel:
					_win = c; break
			if _win == null:
				for c in get_children():
					if c is Control and c != _back:
						_win = c; break

	# Children under Window (only if _win exists)
	if _win != null:
		if title_path != NodePath(""):
			_title = get_node_or_null(title_path) as Label
		else:
			_title = _win.get_node_or_null("VBox/Title") as Label

		if resume_btn_path != NodePath(""):
			_resume = get_node_or_null(resume_btn_path) as Button
		else:
			_resume = _win.get_node_or_null("VBox/ResumeBtn") as Button

		if options_btn_path != NodePath(""):
			_options_btn = get_node_or_null(options_btn_path) as Button
		else:
			_options_btn = _win.get_node_or_null("VBox/OptionsBtn") as Button

		if quit_btn_path != NodePath(""):
			_quit = get_node_or_null(quit_btn_path) as Button
		else:
			_quit = _win.get_node_or_null("VBox/QuitBtn") as Button

		if options_box_path != NodePath(""):
			_options = get_node_or_null(options_box_path) as VBoxContainer
		else:
			_options = _win.get_node_or_null("Options") as VBoxContainer

		if volume_slider_path != NodePath(""):
			_slider = get_node_or_null(volume_slider_path) as HSlider
		else:
			_slider = _win.get_node_or_null("Options/VolRow/Volume") as HSlider

		if tip_label_path != NodePath(""):
			_tip = get_node_or_null(tip_label_path) as Label
		else:
			_tip = _win.get_node_or_null("Options/Tip") as Label

	print("[PauseMenu] back=", _back and _back.name, " | win=", _win and _win.name)

func _style() -> void:
	# Backdrop
	if _back is Panel:
		var sb_back := StyleBoxFlat.new()
		sb_back.bg_color = Color(0,0,0,0.65)
		(_back as Panel).add_theme_stylebox_override("panel", sb_back)
	elif _back is ColorRect:
		(_back as ColorRect).color = Color(0,0,0,0.65)

	# Window border (only if it's a Panel)
	if _win is Panel:
		var sb_win := StyleBoxFlat.new()
		sb_win.bg_color = Color(0,0,0,0.85)
		sb_win.border_width_left = 2
		sb_win.border_width_top = 2
		sb_win.border_width_right = 2
		sb_win.border_width_bottom = 2
		sb_win.border_color = Color(0.0,1.0,0.7,0.9)
		(_win as Panel).add_theme_stylebox_override("panel", sb_win)

	# Mono fonts
	var sys := SystemFont.new()
	sys.font_names = ["Cascadia Mono","Consolas","JetBrains Mono","DejaVu Sans Mono","Noto Sans Mono","monospace"]

	if _title:
		var ls_title := LabelSettings.new()
		ls_title.font = sys; ls_title.font_size = 42
		ls_title.font_color = Color(0.0,1.0,0.7)
		ls_title.outline_size = 2; ls_title.outline_color = Color(0,0,0,0.95)
		_title.label_settings = ls_title
		_title.text = "PAUSE ▮"

	var ls := LabelSettings.new()
	ls.font = sys; ls.font_size = 24
	ls.font_color = Color(0.0,1.0,0.7)
	ls.outline_size = 2; ls.outline_color = Color(0,0,0,0.95)

	var vol_label: Label = null
	if _win: vol_label = _win.get_node_or_null("Options/VolRow/VolLabel") as Label
	if vol_label: vol_label.label_settings = ls
	if _tip:
		_tip.label_settings = ls
		_tip.text = "▲/▼ or drag — ESC resumes"

	for b in [_resume, _options_btn, _quit]:
		if b == null: continue
		b.text = "[ " + b.name.replace("Btn","").to_upper() + " ]"
		b.focus_mode = Control.FOCUS_ALL
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0,0,0,0.0)
		sb.border_color = Color(0.0,1.0,0.7,0.9)
		sb.border_width_bottom = 2
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		var bs := SystemFont.new(); bs.font_names = sys.font_names
		b.add_theme_font_override("font", bs)
		b.add_theme_font_size_override("font_size", 24)
		b.add_theme_color_override("font_color", Color(0.0,1.0,0.7))
		b.add_theme_color_override("font_hover_color", Color(0.0,1.0,0.9))
		b.add_theme_color_override("font_pressed_color", Color(0.0,1.0,0.5))

	if _slider:
		_slider.min_value = 0; _slider.max_value = 1; _slider.step = 0.01
		var vol_db := AudioServer.get_bus_volume_db(0)
		_slider.value = (db_to_linear(vol_db) if vol_db > -40.0 else 0.0)

func _wire() -> void:
	if _resume:
		_resume.pressed.connect(func():
			if has_node("/root/UIManager"): UIManager.close_all()
		)
	if _options_btn and _options:
		_options_btn.pressed.connect(func(): _options.visible = not _options.visible)
	if _quit:
		_quit.pressed.connect(func(): get_tree().quit())
	if _slider:
		_slider.value_changed.connect(func(v: float):
			AudioServer.set_bus_volume_db(0, linear_to_db(clamp(v, 0.0001, 1.0)))
		)
