# SmartCamera2D.gd (Godot 4.x)
extends Camera2D

# Drag your Player node here in the Inspector.
@export var target: Node2D

# Optional auto-find if you don't set target
@export var auto_find_target := true
@export var target_group := "player"
@export var prefer_parent_if_child := true

# --- Tuning ---
@export var follow_speed := 8.0
@export var use_deadzone := true
@export var deadzone_size := Vector2(160, 90)
@export var lookahead_distance := 96.0
@export var lookahead_smoothing := 8.0

# Optional world limits
@export var use_limits := false
@export var limits_rect := Rect2(Vector2.ZERO, Vector2.ZERO)

# --- Internals ---
var _lookahead := Vector2.ZERO
var _last_target_pos := Vector2.ZERO
var _shake_t := 0.0
var _shake_strength := 0.0
var _rng := RandomNumberGenerator.new()

func _ready() -> void:
	enabled = true  # Godot 4: activates this camera
	_rng.randomize()

	# Auto-resolve target if not set
	if not target and prefer_parent_if_child and get_parent() is Node2D:
		target = get_parent() as Node2D
	if not target and auto_find_target:
		target = get_tree().get_first_node_in_group(target_group) as Node2D

	if target:
		_last_target_pos = target.global_position
	else:
		push_warning("SmartCamera2D: No target set. Drag your Player here or put it in the 'player' group.")

	if use_limits:
		_apply_limits(limits_rect)

func _apply_limits(rect: Rect2) -> void:
	# Helper that sets the built-in Camera2D limit_* properties
	limit_left = int(rect.position.x)
	limit_top = int(rect.position.y)
	limit_right = int(rect.position.x + rect.size.x)
	limit_bottom = int(rect.position.y + rect.size.y)

func shake(duration: float = 0.2, strength: float = 4.0) -> void:
	_shake_t = duration
	_shake_strength = strength

func _process(delta: float) -> void:
	if not target:
		return

	var dt: float = delta if delta > 0.000001 else 0.000001

	var est_vel: Vector2 = (target.global_position - _last_target_pos) / dt
	_last_target_pos = target.global_position

	var speed: float = est_vel.length()
	var la_factor: float = clamp(speed / 250.0, 0.0, 1.0)
	var desired_la: Vector2 = est_vel.normalized() * lookahead_distance * la_factor
	_lookahead = _lookahead.lerp(desired_la, 1.0 - pow(0.001, delta * lookahead_smoothing))

	var desired: Vector2 = target.global_position + _lookahead
	if use_deadzone:
		desired = _apply_deadzone(desired)

	global_position = global_position.lerp(desired, 1.0 - pow(0.001, delta * follow_speed))

	if _shake_t > 0.0:
		_shake_t -= delta
		offset = Vector2(_rng.randf_range(-_shake_strength, _shake_strength),
						 _rng.randf_range(-_shake_strength, _shake_strength))
	else:
		offset = Vector2.ZERO



func _apply_deadzone(desired: Vector2) -> Vector2:
	var half := deadzone_size * 0.5
	var cam := global_position
	var minp := cam - half
	var maxp := cam + half
	var out := cam
	if desired.x < minp.x:
		out.x = desired.x + half.x
	elif desired.x > maxp.x:
		out.x = desired.x - half.x
	if desired.y < minp.y:
		out.y = desired.y + half.y
	elif desired.y > maxp.y:
		out.y = desired.y - half.y
	return out
