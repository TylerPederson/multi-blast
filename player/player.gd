extends CharacterBody2D

@export var movement_speed = 300
@export var gravity = 30
@export var jump_strength = 600
@export var max_jumps = 1

@export var player_sprite : AnimatedSprite2D
@export var player_camera : PackedScene
@export var camera_height = -200

@onready var initial_sprite_scale = player_sprite.scale

var jump_count = 0
var camera_instance

var owner_id = 1

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
	
	var is_falling = velocity.y > 0.0 and not is_on_floor()
	var is_jumping = Input.is_action_just_pressed("jump") and is_on_floor()
	var is_double_jumping = Input.is_action_just_pressed("jump") and is_falling
	var is_idle = is_zero_approx(horizontal_input) and is_on_floor()
	var is_walking = Input.is_action_pressed("move_left") or Input.is_action_pressed("move_right")
	var is_jump_cancelled = Input.is_action_just_released("jump") and velocity.y < 0.0
	
	if is_jumping:
		velocity.y = -jump_strength
		jump_count += 1
	elif is_double_jumping:
		jump_count += 1
		if jump_count <= max_jumps:
			velocity.y = -jump_strength
	elif is_jump_cancelled:
		velocity.y = 0.0
	elif is_on_floor():
		jump_count = 0
	
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
	elif is_double_jumping:
		player_sprite.play("double_jump_start")
	elif is_jump_cancelled:
		player_sprite.play("jump")


func _on_animated_sprite_2d_animation_finished() -> void:
	player_sprite.play("jump")

func _set_up_camera():
	camera_instance = player_camera.instantiate()
	camera_instance.global_position.y = camera_height
	get_tree().current_scene.add_child.call_deferred(camera_instance)

func _update_camera_pos():
	camera_instance.global_position.x = global_position.x
