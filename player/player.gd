extends CharacterBody2D

@export var movement_speed = 300
@export var gravity = 30
@export var jump_strength = 600

@export var player_sprite : AnimatedSprite2D

@onready var initial_sprite_scale = player_sprite.scale


func _physics_process(delta: float) -> void:
	var horizontal_input = (
		Input.get_action_strength("move_right")
		- Input.get_action_strength("move_left")
	)
	
	velocity.x = horizontal_input * movement_speed
	velocity.y += gravity
	
	var is_falling = velocity.y > 0.0 and not is_on_floor()
	var is_jumping = Input.is_action_just_pressed("jump") and is_on_floor()
	var is_idle = is_zero_approx(horizontal_input) and is_on_floor()
	var is_walking = Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")
	var is_jump_cancelled = Input.is_action_just_released("jump") and velocity.y > 0.0
	
	if is_jumping:
		velocity.y = -jump_strength
	
	move_and_slide()
	
	if is_idle:
		player_sprite.play("idle")
	
	elif is_walking:
		if horizontal_input < 0:
			player_sprite.scale = Vector2(-initial_sprite_scale.x, initial_sprite_scale.y)
		else:
			player_sprite.scale = Vector2(initial_sprite_scale)
		player_sprite.play("walk")
	
	elif is_falling:
		player_sprite.play("fall")
	elif is_jumping:
		player_sprite.play("jump_start")
	elif is_jump_cancelled:
		player_sprite.play("jump")
