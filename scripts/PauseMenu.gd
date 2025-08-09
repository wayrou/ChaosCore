extends Control

@onready var _back = $Backdrop                 # Panel or ColorRect
@onready var _win  = $Window                   # Panel

@onready var _title: Label        = $VBox/Title
@onready var _resume: Button      = $VBox/ResumeBtn
@onready var _options_btn: Button = $VBox/OptionsBtn
@onready var _quit: Button        = $VBox/QuitBtn

@onready var _options: VBoxContainer = $Options
@onready var _slider: HSlider        = $Options/VolRow/Volume
@onready var _tip: Label             = $Options/Tip

func _ready() -> void:
	for n in [_back, _win, _title, _resume, _options_btn, _quit, _options, _slider, _tip]:
		if n == null:
			push_error("PauseMenu: path mismatch. Check Root -> Backdrop/Window/VBox/Options.")
			return
	_style_terminal()
	_wire_buttons()

func _style_terminal() -> void:
	# Backdrop
	if _back is Panel:
		var sb_back := StyleBoxFlat.new()
		sb_back.bg_color = Color(0,0,0,0.65)
		(_back as Panel).add_theme_stylebox_override("panel", sb_back)
	elif _back is ColorRect:
		(_back as ColorRect).color = Color(0,0,0,0.65)

	# Window
	if _win is Panel:
		var sb_win := StyleBoxFlat.new()
		sb_win.bg_color = Color(0,0,0,0.85)
		sb_win.border_width_left = 2
		sb_win.border_width_top = 2
		sb_win.border_width_right = 2
		sb_win.border_width_bottom = 2
		sb_win.border_color = Color(0.0, 1.0, 0.7, 0.9)
		(_win as Panel).add_theme_stylebox_override("panel", sb_win)

	# Fonts
	var sys := SystemFont.new()
	sys.font_names = ["Cascadia Mono","Consolas","JetBrains Mono","DejaVu Sans Mono","Noto Sans Mono","monospace"]

	var ls_title := LabelSettings.new()
	ls_title.font = sys
	ls_title.font_size = 42
	ls_title.font_color = Color(0.0,1.0,0.7)
	ls_title.outline_size = 2
	ls_title.outline_color = Color(0,0,0,0.95)
	_title.label_settings = ls_title
	_title.text = "PAUSE ▮"

	var ls := LabelSettings.new()
	ls.font = sys
	ls.font_size = 24
	ls.font_color = Color(0.0,1.0,0.7)
	ls.outline_size = 2
	ls.outline_color = Color(0,0,0,0.95)

	var vol_label: Label = $Options/VolRow/VolLabel
	if vol_label: vol_label.label_settings = ls
	_tip.label_settings = ls
	_tip.text = "▲/▼ or drag — ESC resumes"

	# Buttons
	for b in [_resume, _options_btn, _quit]:
		b.text = "[ " + b.name.replace("Btn","").to_upper() + " ]"
		b.focus_mode = Control.FOCUS_ALL
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0,0,0,0.0)
		sb.border_color = Color(0.0,1.0,0.7,0.9)
		sb.border_width_bottom = 2
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		var bs := SystemFont.new()
		bs.font_names = sys.font_names
		b.add_theme_font_override("font", bs)
		b.add_theme_font_size_override("font_size", 24)
		b.add_theme_color_override("font_color", Color(0.0,1.0,0.7))
		b.add_theme_color_override("font_hover_color", Color(0.0,1.0,0.9))
		b.add_theme_color_override("font_pressed_color", Color(0.0,1.0,0.5))

	# Slider init
	_slider.min_value = 0
	_slider.max_value = 1
	_slider.step = 0.01
	var vol_db := AudioServer.get_bus_volume_db(0)
	_slider.value = (db_to_linear(vol_db) if vol_db > -40.0 else 0.0)

func _wire_buttons() -> void:
	_resume.pressed.connect(_on_resume)
	_options_btn.pressed.connect(_on_options_toggle)
	_quit.pressed.connect(_on_quit)
	_slider.value_changed.connect(_on_volume_changed)

func _on_resume() -> void:
	if has_node("/root/UIManager"):
		UIManager.close_all()

func _on_options_toggle() -> void:
	_options.visible = not _options.visible

func _on_quit() -> void:
	get_tree().quit()

func _on_volume_changed(v: float) -> void:
	var db := linear_to_db(clamp(v, 0.0001, 1.0))
	AudioServer.set_bus_volume_db(0, db)
