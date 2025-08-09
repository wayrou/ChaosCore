# EnemyLight.gd (Godot 4.4)
extends CharacterBody2D

# --- Movement / Chase ---
@export var move_speed: float = 90.0
@export var accel: float = 800.0
@export var friction: float = 1600.0
@export var detect_radius: float = 240.0
@export var give_up_radius: float = 360.0
@export var stop_distance: float = 16.0        # stop ramming the player
@export var circle_speed_scale: float = 0.6     # strafe when too close

# --- Combat / Tuning ---
@export var hit_points: int = 3                 # ← 3 hits by default (editable)
@export var randomize_hits: bool = false        # set true to randomize to 2–4
@export var knockback: float = 280.0            # impulse applied on being hit
@export var touch_damage: int = 1               # damage to player on contact (if you hook it up)

# Optional: assign in Inspector; otherwise it will auto-find a child named "Hurtbox"
@export var hurtbox: Area2D

var _player: Node2D
var _aggro: bool = false
var _hit_freeze: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	add_to_group("enemy", true)
	_rng.randomize()
	if randomize_hits:
		hit_points = 1 + _rng.randi_range(2, 4) # 2–4 hits

	_player = get_tree().get_first_node_in_group("player") as Node2D

	# Resolve/prepare hurtbox
	if hurtbox == null:
		hurtbox = get_node_or_null("Hurtbox") as Area2D
		if hurtbox == null:
			for c in get_children():
				if c is Area2D:
					hurtbox = c
					break
	if hurtbox:
		hurtbox.monitoring = true
		# Put it on layer 1 and let it SEE layer 1 (player attacks)
		hurtbox.collision_layer = 1
		hurtbox.collision_mask = 1
		var cs := hurtbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if cs and cs.disabled:
			cs.disabled = false
		if not hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
			hurtbox.area_entered.connect(_on_hurtbox_area_entered)
		if not hurtbox.body_entered.is_connected(_on_hurtbox_body_entered):
			hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	else:
		push_warning("EnemyLight: No Area2D hurtbox found. Assign 'hurtbox' or add a child named 'Hurtbox' with a CollisionShape2D.")

func _physics_process(delta: float) -> void:
	# brief freeze after taking a hit (so knockback is visible)
	if _hit_freeze > 0.0:
		_hit_freeze -= delta
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		move_and_slide()
		return

	if _player == null:
		_player = get_tree().get_first_node_in_group("player") as Node2D
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		move_and_slide()
		return

	var to_player: Vector2 = _player.global_position - global_position
	var dist: float = to_player.length()

	if _aggro:
		if dist > give_up_radius:
			_aggro = false
	else:
		if dist <= detect_radius:
			_aggro = true

	if _aggro:
		if dist < stop_distance:
			# Orbit instead of sticking to the player
			var away := (global_position - _player.global_position).normalized()
			var tangent := Vector2(-away.y, away.x)
			var desired := tangent * move_speed * circle_speed_scale + away * move_speed * 0.2
			velocity = velocity.move_toward(desired, accel * delta)
		else:
			var desired := to_player.normalized() * move_speed
			velocity = velocity.move_toward(desired, accel * delta)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, friction * delta)

	move_and_slide()

# --- Damage handling ----------------------------------------------------------

func take_hit(damage: int = 1, from_global: Vector2 = global_position) -> void:
	hit_points -= max(1, damage)

	# Knockback away from hit point + tiny freeze to sell the impact
	var away := (global_position - from_global).normalized()
	velocity += away * knockback
	_hit_freeze = 0.08

	if hit_points <= 0:
		queue_free()

func _on_hurtbox_area_entered(a: Area2D) -> void:
	# Player melee hitboxes should be in group "player_attack"
	if a.is_in_group("player_attack"):
		var dmg := 1
		if a.has_method("get_damage"):
			var v = a.call("get_damage")
			if typeof(v) == TYPE_INT:
				dmg = v
			elif typeof(v) == TYPE_FLOAT:
				dmg = int(v)
		take_hit(dmg, a.global_position)

func _on_hurtbox_body_entered(b: Node2D) -> void:
	# Optional: bullets in group "player_bullet"
	if b.is_in_group("player_bullet"):
		var dmg := 1
		if b.has_method("get_damage"):
			var val = b.call("get_damage")
			if typeof(val) == TYPE_INT:
				dmg = val
			elif typeof(val) == TYPE_FLOAT:
				dmg = int(val)
		take_hit(dmg, b.global_position)

	# Optional touch damage if you want contact harm (hook to your player's take_damage)
	if touch_damage > 0 and b.is_in_group("player") and b.has_method("take_damage"):
		b.call("take_damage", touch_damage)
