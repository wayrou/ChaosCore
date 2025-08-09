# CornerBanner.gd (Godot 4.4) — terminal style
extends Control

@export var use_scene_name: bool = true
@export var text: String = ""
@export_enum("TopLeft", "TopRight", "BottomLeft", "BottomRight") var corner: int = 0
@export var padding: Vector2 = Vector2(12, 8)

# Terminal look
@export var font_size: int = 48
@export var font_outline: int = 2
@export var font_color: Color = Color(0.0, 1.0, 0.7)   # terminal green
@export var outline_color: Color = Color(0, 0, 0, 0.95)

# Background panel
@export var bg_color: Color = Color(0, 0, 0, 0.55)
@export var bg_roundness: int = 8

# System monospace preference list (edit to taste)
@export var mono_font_names: PackedStringArray = [
	"Cascadia Mono", "Consolas", "SF Mono", "Menlo",
	"JetBrains Mono", "Fira Mono", "DejaVu Sans Mono",
	"Noto Sans Mono", "Liberation Mono", "Courier New", "monospace"
]

@onready var bg: Panel = $Background
@onready var label: Label = $Background/Label

func _ready() -> void:
	# Text selection
	var shown: String = text
	if use_scene_name:
		var cs := get_tree().current_scene
		shown = (cs.name if cs != null else "Scene")

	# Build a SystemFont that asks OS for a monospace family
	var sys_font := SystemFont.new()
	sys_font.font_names = mono_font_names

	# Label styling
	var ls := LabelSettings.new()
	ls.font = sys_font
	ls.font_size = font_size
	ls.outline_size = font_outline
	ls.outline_color = outline_color
	ls.font_color = font_color
	label.label_settings = ls
	label.text = shown

	await get_tree().process_frame  # let Label measure itself

	# Size panel to label + padding
	var inner := label.get_minimum_size()
	var box_size := inner + padding * 2.0

	bg.set_anchors_preset(Control.PRESET_TOP_LEFT)
	bg.size = box_size
	label.set_anchors_preset(Control.PRESET_TOP_LEFT)
	label.position = padding

	# Rounded background
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.corner_radius_top_left = bg_roundness
	sb.corner_radius_top_right = bg_roundness
	sb.corner_radius_bottom_left = bg_roundness
	sb.corner_radius_bottom_right = bg_roundness
	bg.add_theme_stylebox_override("panel", sb)

	_place_in_corner()

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_place_in_corner()

func _place_in_corner() -> void:
	var vp := get_viewport_rect().size
	var box := bg.size
	match corner:
		0: position = Vector2(8, 8)  # TopLeft
		1: position = Vector2(vp.x - box.x - 8, 8)  # TopRight
		2: position = Vector2(8, vp.y - box.y - 8)  # BottomLeft
		3: position = Vector2(vp.x - box.x - 8, vp.y - box.y - 8)  # BottomRight
