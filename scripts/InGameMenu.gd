extends Control

@onready var _back: Control = $Backdrop
@onready var _win:  Panel   = $Window

@onready var _title: Label         = $Window/VBox/Title
@onready var _inv_btn: Button      = $Window/VBox/Tabs/InvBtn
@onready var _units_btn: Button    = $Window/VBox/Tabs/UnitsBtn
@onready var _content: Panel       = $Window/VBox/Content
@onready var _text: RichTextLabel  = $Window/VBox/Content/RichTextLabel
@onready var _close: Button        = $Window/VBox/CloseBtn

var _tab := "inventory"

func _ready() -> void:
	if not _validate(): return
	_layout()
	_style()
	_wire()
	_render()

func _validate() -> bool:
	for n in [_back, _win, _title, _inv_btn, _units_btn, _content, _text, _close]:
		if n == null:
			push_error("InGameMenu paths mismatch. Backdrop/Window must be under Root; VBox under Window.")
			return false
	return true

func _layout() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	if _back: _back.set_anchors_preset(Control.PRESET_FULL_RECT)

	if has_node("VBox") and get_node("VBox").get_parent() != _win:
		get_node("VBox").reparent(_win)

	_win.set_anchors_preset(Control.PRESET_CENTER)
	_win.custom_minimum_size = Vector2(720, 420)
	_win.size = _win.custom_minimum_size

func _style() -> void:
	if _back is Panel:
		var sb_back := StyleBoxFlat.new()
		sb_back.bg_color = Color(0,0,0,0.55)
		(_back as Panel).add_theme_stylebox_override("panel", sb_back)
	elif _back is ColorRect:
		(_back as ColorRect).color = Color(0,0,0,0.55)

	var sb_win := StyleBoxFlat.new()
	sb_win.bg_color = Color(0,0,0,0.88)
	sb_win.border_width_left = 2
	sb_win.border_width_top = 2
	sb_win.border_width_right = 2
	sb_win.border_width_bottom = 2
	sb_win.border_color = Color(0.0,1.0,0.7,0.9)
	_win.add_theme_stylebox_override("panel", sb_win)

	var sys := SystemFont.new()
	sys.font_names = ["Cascadia Mono","Consolas","JetBrains Mono","DejaVu Sans Mono","Noto Sans Mono","monospace"]

	var ls_title := LabelSettings.new()
	ls_title.font = sys; ls_title.font_size = 38
	ls_title.font_color = Color(0.0,1.0,0.7)
	ls_title.outline_size = 2; ls_title.outline_color = Color(0,0,0,0.95)
	_title.label_settings = ls_title
	_title.text = "SCROLLLINK OS v2.3 — UNIT CONSOLE"

	for b in [_inv_btn, _units_btn, _close]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0,0,0,0.0)
		sb.border_width_bottom = 2
		sb.border_color = Color(0.0,1.0,0.7,0.9)
		b.add_theme_stylebox_override("normal", sb)
		b.add_theme_stylebox_override("hover", sb)
		b.add_theme_stylebox_override("pressed", sb)
		var bs := SystemFont.new(); bs.font_names = sys.font_names
		b.add_theme_font_override("font", bs)
		b.add_theme_font_size_override("font_size", 22)
		b.add_theme_color_override("font_color", Color(0.0,1.0,0.7))
		b.add_theme_color_override("font_hover_color", Color(0.0,1.0,0.9))

	if _content is Panel:
		var sb_c := StyleBoxFlat.new()
		sb_c.bg_color = Color(0,0,0,0.2)
		sb_c.border_color = Color(0.0,1.0,0.7,0.5)
		sb_c.border_width_left = 1
		sb_c.border_width_top = 1
		sb_c.border_width_right = 1
		sb_c.border_width_bottom = 1
		(_content as Panel).add_theme_stylebox_override("panel", sb_c)

func _wire() -> void:
	_inv_btn.text = "[ INVENTORY ]"
	_units_btn.text = "[ UNITS ]"
	_close.text = "[ CLOSE ]"
	_inv_btn.pressed.connect(func(): _tab = "inventory"; _render())
	_units_btn.pressed.connect(func(): _tab = "units"; _render())
	_close.pressed.connect(func():
		if has_node("/root/UIManager"): UIManager.toggle_game_menu()
	)

func _render() -> void:
	if _tab == "inventory":
		_render_inventory()
	else:
		_render_units()

func _render_inventory() -> void:
	var items: Array[String] = []
	var gs := get_node_or_null("/root/GameState")
	if gs:
		var inv = gs.get("inventory")
		if inv is Array:
			for it in inv: items.append(str(it))
	if items.is_empty(): items = ["<empty>"]

	var out := "[b]INVENTORY[/b]\n"
	for i in range(items.size()):
		out += "  " + str(i+1).pad_zeros(2) + "  " + items[i] + "\n"
	_text.text = ""; _text.append_text(out)

func _render_units() -> void:
	var out := "[b]UNITS[/b]\n  - Elise\n  - (More coming soon)\n\nUse arrow keys/confirm to manage."
	_text.text = ""; _text.append_text(out)
