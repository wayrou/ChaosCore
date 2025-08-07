extends CharacterBody2D

@export var speed := 100.0

var input_vector := Vector2.ZERO

func _process_input():
	input_vector = Vector2(
		Input.get_action_strength("move_right") - Input.get_action_strength("move_left"),
		Input.get_action_strength("move_down") - Input.get_action_strength("move_up")
	).normalized()

func _physics_process(delta):
	_process_input()
	velocity = input_vector * speed
	move_and_slide()
