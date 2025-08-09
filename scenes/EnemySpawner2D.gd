# EnemySpawner2D.gd (Godot 4.4)
@tool
extends Node2D

@export var enabled: bool = true

# What to spawn
@export var enemy_scene: PackedScene            # drag EnemyLight.tscn here
@export var container: Node                     # optional: where to add enemies (e.g., Actors)
@export var player: Node2D                      # optional: auto-finds by group "player" if empty

# Where to spawn (rectangle centered on this node)
@export var spawn_area_size: Vector2 = Vector2(640, 480)
@export var min_player_distance: float = 128.0

# How often / how many
@export var initial_count: int = 3
@export var max_alive: int = 8
@export var spawn_interval: float = 3.0
@export var spawn_interval_jitter: float = 1.5

# Optional blocker probe (set mask=0 to disable)
@export var blockers_mask: int = 1
@export var probe_radius: float = 10.0
@export var tries_per_spawn: int = 10

var _timer: Timer
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
	_rng.randomize()
	if player == null:
		player = get_tree().get_first_node_in_group("player") as Node2D
	if container == null:
		container = get_parent()

	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_timer_timeout)

	if enabled:
		_spawn_initial()
		_arm_timer()

func _process(_dt: float) -> void:
	# keep the editor gizmo fresh
	if Engine.is_editor_hint():
		queue_redraw()

func _draw() -> void:
	# editor gizmo — green rectangle where spawns can appear
	var half: Vector2 = spawn_area_size * 0.5
	var rect := Rect2(-half, spawn_area_size)
	draw_rect(rect, Color(0, 1, 0, 0.07), true)
	draw_rect(rect, Color(0, 1, 0, 0.7), false, 2.0)

func _spawn_initial() -> void:
	for _i in range(initial_count):
		if _alive_count() >= max_alive:
			break
		_spawn_one()

func _arm_timer() -> void:
	var jitter: float = clamp(
		_rng.randf_range(-spawn_interval_jitter, spawn_interval_jitter),
		-spawn_interval + 0.2,
		10.0
	)
	_timer.start(max(0.2, spawn_interval + jitter))

func _on_timer_timeout() -> void:
	if not enabled:
		return
	if _alive_count() < max_alive:
		_spawn_one()
	_arm_timer()

func _alive_count() -> int:
	return get_tree().get_nodes_in_group("enemy").size()

func _spawn_one() -> void:
	if enemy_scene == null:
		push_warning("EnemySpawner: 'enemy_scene' not set.")
		return

	var pos: Vector2 = _pick_spawn_point()
	# Optional: if you really want to skip spawns when we couldn't find a clear spot,
	# compare to a sentinel (e.g., return global_position when failing and check distance to player)

	var inst: Node2D = enemy_scene.instantiate() as Node2D
	inst.global_position = pos
	if container:
		container.add_child(inst)
	else:
		add_child(inst)

func _pick_spawn_point() -> Vector2:
	# Never returns null; falls back to this node's position if no valid point found.
	var half: Vector2 = spawn_area_size * 0.5
	var space := get_world_2d().direct_space_state

	for _t in range(tries_per_spawn):
		var local: Vector2 = Vector2(
			_rng.randf_range(-half.x, half.x),
			_rng.randf_range(-half.y, half.y)
		)
		var pos: Vector2 = to_global(local)

		# keep some distance from player
		if player and pos.distance_to(player.global_position) < min_player_distance:
			continue

		# optional blocker probe (walls/solids on blockers_mask)
		if blockers_mask != 0 and probe_radius > 0.0:
			var shape := CircleShape2D.new()
			shape.radius = probe_radius
			var q := PhysicsShapeQueryParameters2D.new()
			q.shape = shape
			q.transform = Transform2D(0.0, pos)
			q.collide_with_areas = true
			q.collide_with_bodies = true
			q.collision_mask = blockers_mask
			var hits: Array = space.intersect_shape(q, 1)
			if hits.size() > 0:
				continue

		return pos

	# Fallback: spawn at the spawner’s position if all tries failed
	return global_position
