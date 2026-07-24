extends CharacterBody2D

#constant variables are all caps
const SPEED = 500.0
const MAX_SPEED = 300.0
const CAMERA_LERP_SPEED = 500.0
const CAMERA_DIRECTION_MULTIPLIER =0.0
const DOWN_TO_MAX_SPEED = 300.0
const DRAG = 1000.0
const DASH_SPEED = 500.0
const DASH_COOLDOWN = 1.5

# regular variables are snake_case
var can_dash := true 

var health := 100.0

@export var player_camera : Camera2D
@export var gun : Node2D
@export var controller : Node2D

@onready var dash_sound : AudioStreamPlayer = %DashSound
@onready var melee_area : Area2D = %MeleeAttackArea

#func _process(delta: float) -> void:
	

func _physics_process(delta: float) -> void:
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	
	player_camera.global_position = player_camera.global_position.move_toward(global_position + (velocity * CAMERA_DIRECTION_MULTIPLIER), CAMERA_LERP_SPEED * delta)
	
	
	if controller.action_state:
		
		var look_direction = get_global_mouse_position() - global_position
		var gun_angle = look_direction.angle()
		gun.global_rotation = gun_angle
		
	
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	var target_velocity := direction * MAX_SPEED

# handle acceleration on active axes
	if direction.x != 0:
		velocity.x = move_toward(velocity.x, target_velocity.x, SPEED * delta)
	if direction.y != 0:
		velocity.y = move_toward(velocity.y, target_velocity.y, SPEED * delta)

# handle drag on axes with no input
	if direction.x == 0:
		velocity.x = move_toward(velocity.x, 0, DRAG * delta)
	if direction.y == 0:
		velocity.y = move_toward(velocity.y, 0, DRAG * delta)

	# slowly bring above max velocity back down to MAX_SPEED after dashes/boosts
	if velocity.length() > MAX_SPEED:
	# Only pull back if the player isn't actively forcing an over-speed state (optional check)
		var target_length = move_toward(velocity.length(), MAX_SPEED, DOWN_TO_MAX_SPEED * delta)
		velocity = velocity.limit_length(target_length)
		
	if Input.is_action_just_pressed("dash"):
		if can_dash:
			velocity += direction * DASH_SPEED
			can_dash = false
			dash_sound.play()
			await get_tree().create_timer(DASH_COOLDOWN).timeout
			can_dash = true
	
	if Input.is_action_just_pressed("stab_attack"):
		stab_attack()
		

	move_and_slide()
	
func take_damage(damage : float):
	health -= damage
	print(health)
	if health <= 0:
		print("player died")
		get_tree().change_scene_to_file("res://Scenes/game_over_scene.tscn")


func stab_attack():
	pass
