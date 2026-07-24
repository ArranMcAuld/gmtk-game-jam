class_name base_grenade
extends RigidBody2D

var detonate_cooldown : float = 10.0
const SHOOT_SPEED : float = 500.0
@export var collision : CollisionShape2D
@export var grenade_name : String
@export var damage : float = 5.0
@export var regular_explosive: bool = true

@onready var explosion_sound : AudioStreamPlayer = %AudioStreamPlayer
@onready var explosion_area : Area2D = %ExplosionArea2D



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
	
	if regular_explosive:
		explosion_sound.get_parent().remove_child(explosion_sound)
		get_tree().current_scene.add_child(explosion_sound)
	
		# 2. Play the sound and connect it to self-destruct when done
		explosion_sound.play()
		explosion_sound.finished.connect(explosion_sound.queue_free)
		print("BOOM! Grenade exploded!")
	
		var overlapping_stuff = explosion_area.get_overlapping_bodies()
		for object in overlapping_stuff:
			if object.is_in_group("enemy"):
				if object.has_method("take_damage"):
					object.take_damage(damage,global_position) 
	
	
	
		queue_free()
	else:
		custom_explosion_logic()
		
func custom_explosion_logic():
	pass
