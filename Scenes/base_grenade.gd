class_name base_grenade
extends RigidBody2D

var detonate_cooldown : float = 20.0
const SHOOT_SPEED : float = 200.0

#stuff to change for each grenade

	
# We call this on the player when the bullet is shot
func launch(direction: Vector2) -> void:
	global_rotation = direction.angle()
	# apply force
	apply_central_impulse(direction * SHOOT_SPEED)
	
	#wait for cooldown
	await get_tree().create_timer(detonate_cooldown).timeout
	
	# explosion function
	
	
	# destroy grenade
	queue_free()
	
