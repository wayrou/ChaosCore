extends CharacterBody2D

# --- Movement ---
@export var speed: float = 100.0
@export var sprint_multiplier: float = 1.6
@export var accel: float = 2200.0
@export var decel: float = 2600.0

# --- Combat / Health ---
signal health_changed(current: int, max: int)

# Add near your other vars (top of script)
@export var attack_hitbox: Area2D
@export var hurtbox: Area2D
@export var debug_attack: bool = true


@export var max_hp: int = 5
@export var invincible_time: float = 0.6      # i-frames after getting hit (sec)

@export var attack_cooldown: float = 0.25     # time between swings
@export var attack_duration: float = 0.10     # how long the hitbox is active
@export var attack_offset: float = 26.0      # distance from player to start of hit
@export var attack_length: float = 44.0      # long dimension of the rectangle
@export var attack_thickness: float = 18.0   # short dimension (height)

@export_file("*.tscn") var respawn_scene: String = ""               # set to BaseCamp.tscn
@export var respawn_spawn_name: StringName = &"fromDungeonFloor"    # marker in BaseCamp/SpawnPoints
@export var heal_on_respawn: bool = true                            # toggle full heal on respawn



# Drag these in the Inspector (or leave empty to auto-find by name)



var hp: int
var input_vector: Vector2 = Vector2.ZERO
var _last_dir: Vector2 = Vector2.RIGHT
var _attack_cd: float = 0.0
var _inv: float = 0.0
var _attacking: bool = false
var _attack_shape: CollisionShape2D

var _dead: bool = false


# Replace your _ready() setup block with this
func _ready() -> void:
	add_to_group("player", true)

	hp = max_hp
	emit_signal("health_changed", hp, max_hp)

	_ensure_attack_hitbox()
	_ensure_hurtbox()


	# Resolve nodes if not set
	if attack_hitbox == null:
		attack_hitbox = get_node_or_null("AttackHitbox") as Area2D
	if hurtbox == null:
		hurtbox = get_node_or_null("Hurtbox") as Area2D

	# Attack hitbox setup
	if attack_hitbox:
		attack_hitbox.add_to_group("player_attack", true)
		attack_hitbox.monitoring = false  # enemy hurtbox will do the monitoring
		# Put the attack on Physics Layer 1 (default) and don't scan anything ourselves
		attack_hitbox.collision_layer = 1
		attack_hitbox.collision_mask = 0

		var cs := attack_hitbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if cs:
			cs.disabled = true  # start disabled

	if debug_attack:
		attack_hitbox.area_entered.connect(_on_attack_hitbox_area_entered)
		attack_hitbox.body_entered.connect(_on_attack_hitbox_body_entered)
		
func _on_attack_hitbox_area_entered(a: Area2D) -> void:
	print("[ATTACK] overlapped AREA:", a.name, " groups:", a.get_groups())

	# Hurtbox listens for enemy touch damage (enemies can just be in group "enemy")
	if hurtbox:
		hurtbox.monitoring = true
		var hc := hurtbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
		if hc and hc.disabled: hc.disabled = false
		hurtbox.body_entered.connect(_on_hurtbox_body_entered)
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func _get_input_vector() -> Vector2:
	return Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()

func _physics_process(delta: float) -> void:
	# timers
	if _attack_cd > 0.0: _attack_cd -= delta
	if _inv > 0.0: _inv -= delta

	# movement
	input_vector = _get_input_vector()
	var moving := input_vector != Vector2.ZERO
	if moving:
		_last_dir = input_vector

	var want_sprint := Input.is_action_pressed("sprint") and moving
	var target_speed := speed * (sprint_multiplier if want_sprint else 1.0)
	var desired_vel := input_vector * target_speed
	var rate := (accel if moving else decel) * delta
	velocity = velocity.move_toward(desired_vel, rate)
	move_and_slide()

	# attack input
	if Input.is_action_just_pressed("attackFreeMove"):
		_try_attack()

func _try_attack() -> void:
	if _attacking or _attack_cd > 0.0 or attack_hitbox == null:
		return
	if debug_attack: print("[ATTACK] pressed")

	_attacking = true
	_attack_cd = attack_cooldown

	var dir := (_last_dir if _last_dir != Vector2.ZERO else Vector2.RIGHT).normalized()

	# Face the swing direction
	attack_hitbox.rotation = dir.angle()

	# Push the box out so it clears your body:
	# start at attack_offset + half the hit length along the local X axis (the long side)
	attack_hitbox.position = dir * (attack_offset + attack_length * 0.5)

	# (optional) ensure size is up-to-date if you tweak exports at runtime
	if _attack_shape and _attack_shape.shape is RectangleShape2D:
		(_attack_shape.shape as RectangleShape2D).size = Vector2(attack_length, attack_thickness)
		_attack_shape.disabled = false

	attack_hitbox.monitoring = true

	var t := get_tree().create_timer(attack_duration)
	await t.timeout

	if _attack_shape: _attack_shape.disabled = true
	attack_hitbox.monitoring = false
	_attacking = false



# --- Taking damage / death ---

func take_damage(amount: int = 1) -> void:
	if _inv > 0.0:
		return
	hp = clamp(hp - max(1, amount), 0, max_hp)
	_inv = invincible_time
	emit_signal("health_changed", hp, max_hp)
	# TODO: flash sprite or play SFX here

	if hp <= 0:
		_on_player_death()

func _on_player_death() -> void:
	if _dead: 
		return
	_dead = true

	if respawn_scene == "":
		push_warning("Player: respawn_scene not set — staying in scene.")
		# If you don’t want an instant refill in this fallback, comment the next 2 lines:
		hp = max_hp
		emit_signal("health_changed", hp, max_hp)
		_dead = false
		return

	# Optional: choose whether to heal on respawn
	if heal_on_respawn:
		hp = max_hp
	else:
		# keep at 0; the HUD will show 0/Max until the new scene loads
		pass
	emit_signal("health_changed", hp, max_hp)

	# Prefer SceneManager so we land on the spawn marker
	var sm := get_node_or_null("/root/sceneManager")
	if sm:
		sm.change_scene(respawn_scene, respawn_spawn_name)
		return

	# Fallback if SceneManager missing: stash spawn and switch scenes
	Engine.set_meta("spawn_name", respawn_spawn_name)
	var err := get_tree().change_scene_to_file(respawn_scene)
	if err != OK:
		push_error("Respawn failed: %s" % err)
		_dead = false  # let another death attempt try again



# Hurtbox callbacks: touch damage from enemies / enemy attacks
func _on_hurtbox_body_entered(b: Node2D) -> void:
	if b.is_in_group("enemy"):
		take_damage(1)

func _on_hurtbox_area_entered(a: Area2D) -> void:
	if a.is_in_group("enemy_attack"):
		take_damage(1)
		
# Helpers (put anywhere in the script)

func _ensure_attack_hitbox() -> void:
	if attack_hitbox == null:
		attack_hitbox = get_node_or_null("AttackHitbox") as Area2D
	if attack_hitbox == null:
		attack_hitbox = Area2D.new()
		attack_hitbox.name = "AttackHitbox"
		add_child(attack_hitbox)
		var cs := CollisionShape2D.new()
		cs.name = "CollisionShape2D"
		var shape := RectangleShape2D.new()
		shape.size = Vector2(attack_length, attack_thickness)
		cs.shape = shape
		attack_hitbox.add_child(cs)

	attack_hitbox.add_to_group("player_attack", true)
	attack_hitbox.collision_layer = 1
	attack_hitbox.collision_mask = 1
	attack_hitbox.monitoring = false

	_attack_shape = attack_hitbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if _attack_shape:
		_attack_shape.disabled = true
		if _attack_shape.shape is RectangleShape2D:
			(_attack_shape.shape as RectangleShape2D).size = Vector2(attack_length, attack_thickness)




func _ensure_hurtbox() -> void:
	if hurtbox == null:
		hurtbox = get_node_or_null("Hurtbox") as Area2D
	if hurtbox == null:
		# optional: create one if you don't have it yet
		hurtbox = Area2D.new()
		hurtbox.name = "Hurtbox"
		add_child(hurtbox)
		var cs := CollisionShape2D.new()
		cs.name = "CollisionShape2D"
		var shape := CircleShape2D.new()
		shape.radius = 10
		cs.shape = shape
		hurtbox.add_child(cs)

	hurtbox.monitoring = true
	# make sure it can SEE the attack (which is on layer 1)
	hurtbox.collision_mask = hurtbox.collision_mask | 1

	var hc := hurtbox.get_node_or_null("CollisionShape2D") as CollisionShape2D
	if hc and hc.disabled: hc.disabled = false

	if not hurtbox.body_entered.is_connected(_on_hurtbox_body_entered):
		hurtbox.body_entered.connect(_on_hurtbox_body_entered)
	if not hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)

func _on_attack_hitbox_body_entered(b: Node2D) -> void:
	print("[ATTACK] overlapped BODY:", b.name, " groups:", b.get_groups())
