extends Node2D

var grenade_inventory: Array[base_grenade] = []

@export var spawn_pos : Node2D
@onready var shoot_sound : AudioStreamPlayer = %GrenadeShoot

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("shoot"):
		if Engine.time_scale != 0.0:
			var bullet = grenade_inventory.pop_front()
			if bullet:
				bullet.launch(spawn_pos.global_position, global_rotation)
				shoot_sound.play()
			else:
				print("no grenade")
		
func get_grenades(grenades : Array[base_grenade]) -> void:
	grenade_inventory = grenades
	for bullet in grenade_inventory:
		bullet.reparent(self)
		bullet.global_position = global_position
	
