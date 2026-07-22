extends CharacterBody2D

const SPEED = 300.0
const CAMERA_LERP_SPEED = 350.0
const CAMERA_DIRECTION_MULTIPLIER = 10.0

@export var player_camera : Camera2D
@export var gun : Node2D

#func _process(delta: float) -> void:
	

func _physics_process(delta: float) -> void:
	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	
	
	player_camera.global_position = player_camera.global_position.move_toward(global_position + (velocity * CAMERA_DIRECTION_MULTIPLIER), CAMERA_LERP_SPEED * delta)
	
	var look_direction = get_global_mouse_position() - global_position
	var gun_angle = look_direction.angle()
	gun.global_rotation = gun_angle
		
	
	var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if direction:
		velocity = direction * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.y = move_toward(velocity.y, 0, SPEED)

	move_and_slide()
