extends Area2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


@export var speed: float = 600.0
@export var damage: float = 10.0

func _physics_process(delta: float) -> void:
	# Moves the bullet in the direction it is facing, adjusted for frame rate
	position += transform.x * speed * delta
	

func _on_body_entered(body: Node2D) -> void:
	# Checks if the object belongs to the "player" group
	if body.is_in_group("player"):
		body.take_damage(damage)
	queue_free()
