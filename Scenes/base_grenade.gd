class_name base_grenade
extends RigidBody2D

var detonate_cooldown : float = 10.0
const SHOOT_SPEED : float = 500.0
@export var collision : CollisionShape2D
@export var grenade_name : String


func _ready() -> void:
	pass


# Call this when ACTION mode starts
func start_countdown() -> void:
	await get_tree().create_timer(detonate_cooldown).timeout
	detonate()


# Call this when the player fires the gun
func launch(spawn_position: Vector2, rotation: float) -> void:
	top_level = true
	global_position = spawn_position
	visible = true
	collision.set_deferred("disabled", false)
	global_rotation = rotation
	apply_central_impulse(Vector2.from_angle(rotation) * SHOOT_SPEED)


func detonate() -> void:
	print("BOOM! Grenade exploded!")
	# Add explosion effects/damage here
	queue_free()
