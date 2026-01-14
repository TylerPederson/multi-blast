extends CharacterBody2D

@export var movement_speed = 300
@export var gravity = 30
@export var jump_strength = 600
@export var max_jumps = 1

@export var player_sprite : AnimatedSprite2D
@export var player_camera : PackedScene
@export var camera_height = -200

@onready var initial_sprite_scale = player_sprite.scale

var owner_id = 1
var jump_count = 0
var camera_instance
var state = PlayerState.IDLE

enum PlayerState {
	IDLE,
	WALKING,
	JUMP_STARTED,
	JUMPING,
	DOUBLE_JUMPING,
	FALLING
}

func _enter_tree():
	owner_id = name.to_int()
	set_multiplayer_authority(owner_id)
	if owner_id != multiplayer.get_unique_id():
		return
	_set_up_camera()

func _process(_delta):
	if multiplayer.multiplayer_peer == null:
		return
	if owner_id != multiplayer.get_unique_id():
		return
	_update_camera_pos()

func _physics_process(delta: float) -> void:
	if owner_id != multiplayer.get_unique_id():
		return
	
	var horizontal_input = (
		Input.get_action_strength("move_right")
		- Input.get_action_strength("move_left")
	)
	
	velocity.x = horizontal_input * movement_speed
	velocity.y += gravity
	
	move_and_slide()
	handle_movement_state()

func handle_movement_state():
	# Decide State
	if Input.is_action_just_pressed("jump") and is_on_floor():
		state = PlayerState.JUMP_STARTED
	elif is_zero_approx(velocity.x) and is_on_floor():
		state = PlayerState.IDLE
	elif Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right"):
		state = PlayerState.WALKING
	else:
		state = PlayerState.JUMPING
	if velocity.y > 0.0 and not is_on_floor():
		if Input.is_action_just_pressed("jump"):
			state = PlayerState.DOUBLE_JUMPING
		else:
			state = PlayerState.FALLING
	match state:
		PlayerState.IDLE:
			player_sprite.play("idle")
			jump_count = 0
		PlayerState.WALKING:
			player_sprite.play("walk")
			if velocity.x < 0:
				player_sprite.scale = Vector2(-initial_sprite_scale.x, initial_sprite_scale.y)
			else:
				player_sprite.scale = Vector2(initial_sprite_scale)
			jump_count = 0
		PlayerState.JUMP_STARTED:
			player_sprite.play("jump_start")
			jump_count += 1
			velocity.y = -jump_strength
		PlayerState.JUMPING:
			pass
		PlayerState.DOUBLE_JUMPING:
			player_sprite.play("double_jump_start")
			jump_count += 1
			if jump_count <= max_jumps:
				velocity.y = -jump_strength
		PlayerState.FALLING:
			player_sprite.play("fall")
	
	if Input.is_action_just_released("jump") and velocity.y < 0.0:
		velocity.y = 0.0

func _on_animated_sprite_2d_animation_finished() -> void:
	if state == PlayerState.JUMPING:
		player_sprite.play("jump")

func _set_up_camera():
	camera_instance = player_camera.instantiate()
	camera_instance.global_position.y = camera_height
	get_tree().current_scene.add_child.call_deferred(camera_instance)

func _update_camera_pos():
	camera_instance.global_position.x = global_position.x
