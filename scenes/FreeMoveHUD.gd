extends Control

@export var bar_len: int = 12
@export var font_size: int = 36
@export var font_color: Color = Color(0.0, 1.0, 0.7)
@export var outline_color: Color = Color(0, 0, 0, 0.95)
@export var padding: Vector2 = Vector2(12, 8)
@export_enum("TopLeft", "TopRight", "BottomLeft", "BottomRight") var corner: int = 1  # default TopRight

@onready var label: Label = $Label

func _ready() -> void:
	# monospace look
	var sys := SystemFont.new()
	sys.font_names = ["Cascadia Mono","Consolas","JetBrains Mono","DejaVu Sans Mono","Noto Sans Mono","monospace"]
	var ls := LabelSettings.new()
	ls.font = sys
	ls.font_size = font_size
	ls.font_color = font_color
	ls.outline_size = 2
	ls.outline_color = outline_color
	label.label_settings = ls

	# screen-space placement
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.position = padding

	# connect to player
	var p := get_tree().get_first_node_in_group("player")
	if p:
		p.health_changed.connect(_on_health_changed)
		_on_health_changed(p.hp, p.max_hp)

	_place_in_corner()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_place_in_corner()

func _on_health_changed(h: int, m: int) -> void:
	var filled: int = int(round(float(h) / float(max(1, m)) * float(bar_len)))
	var bar: String = _repeat_char("#", filled) + _repeat_char("-", bar_len - filled)
	label.text = "HP [" + bar + "]  " + str(h) + "/" + str(m)
	await get_tree().process_frame  # let label size update
	_place_in_corner()

func _place_in_corner() -> void:
	var vp := get_viewport_rect().size
	var box := label.get_minimum_size() + padding * 2.0
	match corner:
		0: position = Vector2(8, 8)                                  # TopLeft
		1: position = Vector2(vp.x - box.x - 8, 8)                    # TopRight
		2: position = Vector2(8, vp.y - box.y - 8)                    # BottomLeft
		3: position = Vector2(vp.x - box.x - 8, vp.y - box.y - 8)     # BottomRight

func _repeat_char(ch: String, count: int) -> String:
	if count <= 0: return ""
	var out := ""
	for _i in count: out += ch
	return out
