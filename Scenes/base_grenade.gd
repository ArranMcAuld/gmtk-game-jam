class_name base_grenade
extends RigidBody2D

var detonate_cooldown : float = 10.0
const SHOOT_SPEED : float = 500.0
@export var collision : CollisionShape2D

#stuff to change for each grenade


func _ready() -> void:
	#wait for cooldown
	await get_tree().create_timer(detonate_cooldown).timeout
	
	# explosion function
	
	
	# destroy grenade
	queue_free()

# We call this on the player when the bullet is shot
func launch(spawn_position: Vector2, rotation: float) -> void:
	top_level = true # this essentially unparents it
	global_position = spawn_position
	visible = true
	collision.set_deferred("disabled", false) 
	global_rotation = rotation
	# apply force
	apply_central_impulse(Vector2.from_angle(rotation) * SHOOT_SPEED)

	
	
	
