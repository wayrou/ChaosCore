# WorldText2D.gd (Godot 4.4)
extends Node2D

@export var text: String = "baseCamp"
@export var font_size: int = 64
@export var color: Color = Color.WHITE
@export var outline_size: int = 2
@export var outline_color: Color = Color(0, 0, 0, 0.85)

@export var keep_pixel_size: bool = false   # stays same size regardless of zoom
@export var debug: bool = true

var _font: Font

func _ready() -> void:
	# Make sure we’re in world space & on top of tiles
	set_as_top_level(false)   # CanvasItem → Top Level = Off
	z_as_relative = false
	z_index = 20
	# (Optional) force onto visibility layer 1, the default most cameras render
	visibility_layer = 1

	if debug:
		var p := get_parent()
		while p:
			if p is CanvasLayer: push_warning("Under a CanvasLayer — will look like UI!")
			if p is Camera2D:    push_warning("Child of Camera2D — will look screen-fixed!")
			p = p.get_parent()

	var sf := SystemFont.new()
	sf.font_names = ["Noto Sans", "DejaVu Sans", "Arial"]
	_font = sf

	if debug:
		print("[WorldText2D] READY path=", get_path(), " pos=", global_position)

	queue_redraw()

func _process(_dt: float) -> void:
	if keep_pixel_size:
		var cam := get_viewport().get_camera_2d()
		if cam:
			var z := cam.zoom
			scale = Vector2(1.0 / max(z.x, 0.0001), 1.0 / max(z.y, 0.0001))
	# keep redrawing while debugging so we’re never culled due to stale region
	if debug:
		queue_redraw()

func _draw() -> void:
	# Big colored box so we can’t miss it
	if debug:
		draw_rect(Rect2(Vector2(-8, -8), Vector2(420, 80)), Color(0,0,0,0.5), true, 0.0, true)
		draw_rect(Rect2(Vector2(-8, -8), Vector2(420, 80)), Color(1,1,1,0.75), false, 2.0, true)

	if _font == null:
		return

	# Outline
	if outline_size > 0:
		for o in [Vector2(outline_size,0), Vector2(-outline_size,0), Vector2(0,outline_size), Vector2(0,-outline_size)]:
			draw_string(_font, o, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, outline_color)
	# Main
	draw_string(_font, Vector2.ZERO, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size, color)
