class_name Enemy
extends CharacterBody2D

@export var speed := 300.0
@export var chase_speed := 450.0
@export var is_melee : bool = true
@export var health : float = 5.0
@export var damage : float = 15.0
@export var bullet : PackedScene
@export var chance_to_spawn_bullet : float = 0.01
@export var knockback_force : float = 1000.0

@export var acceleration := 2500.0    # How fast the enemy matches target speed
@export var friction := 15.0          # How fast the enemy stops or turns (higher = sharper turns)
@export var knockback_decay := 5.0    # How fast speeds above max speed bleed off

@onready var vision_area : Area2D = %VisionArea2D
@onready var death_sound : AudioStreamPlayer = %AudioStreamPlayer
@onready var bullet_spawn_pos : Node2D = %BulletSpawnPos

var player : CharacterBody2D = null
var is_player_in_range : bool = false

var target_position := Vector2.ZERO
var wander_timer := 0.0
var current_wander_delay := 2.0

var is_repositioning : bool = false
var reposition_timer := 0.0
var reposition_duration := 0.0

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")
	
	vision_area.body_entered.connect(_on_vision_area_body_entered)
	vision_area.body_exited.connect(_on_vision_area_body_exited)
	
	select_random_target()

func _physics_process(delta: float) -> void:
	# Define our movement targets for this frame
	var desired_velocity := Vector2.ZERO
	var max_allowed_speed := speed

	# reposition
	if is_repositioning:
		reposition_timer += delta
		look_at(target_position)
		
		max_allowed_speed = speed
		desired_velocity = global_position.direction_to(target_position) * max_allowed_speed
		
		# Return to normal behavior if timer expires or destination reached
		if global_position.distance_to(target_position) < 15.0 or reposition_timer >= reposition_duration:
			is_repositioning = false
			wander_timer = 0.0

	# chase
	elif is_player_in_range and player != null:
		max_allowed_speed = chase_speed
		var look_target : Vector2
		
		if is_melee:
			look_target = player.global_position
			target_position = player.global_position
		else:
			var chance_to_shoot: bool = randf() < chance_to_spawn_bullet
			if chance_to_shoot:
				if bullet:
					var bullet_instance = bullet.instantiate()
					get_tree().current_scene.add_child(bullet_instance)
					bullet_instance.global_position = bullet_spawn_pos.global_position
					bullet_instance.look_at(player.global_position)
					
			if target_position == Vector2.ZERO or global_position.distance_to(target_position) < 20.0:
				target_position = get_spot_near_player()
			look_target = target_position
		
		look_at(look_target)
		desired_velocity = global_position.direction_to(target_position) * max_allowed_speed
		
	# wander
	else:
		max_allowed_speed = speed
		
		wander_timer += delta
		if wander_timer >= current_wander_delay:
			select_random_target()
			wander_timer = 0.0
		
		look_at(target_position)
		
		if global_position.distance_to(target_position) < 10.0:
			desired_velocity = Vector2.ZERO
		else:
			desired_velocity = global_position.direction_to(target_position) * max_allowed_speed

	# --- NEW PHYSICS ACCELERATION AND KNOCKBACK MANIPULATION ---
	if desired_velocity.length() > 0:
		# Add to velocity instead of overriding it directly
		velocity += desired_velocity.normalized() * acceleration * delta
		
		# Prevent turning from feeling slippery:
		# Kill momentum that does not align with our intended movement direction
		var forward_velocity = velocity.project(desired_velocity)
		var sideways_velocity = velocity - forward_velocity
		velocity = forward_velocity + sideways_velocity * exp(-friction * delta)
	else:
		# Bring enemy to a clean stop if there is no desired movement input
		velocity = velocity.lerp(Vector2.ZERO, friction * delta)

	# Handle Knockback decay: If going faster than the speed limit, bleed off the excess force smoothly
	if velocity.length() > max_allowed_speed:
		var excess_speed = velocity.length() - max_allowed_speed
		excess_speed = lerp(excess_speed, 0.0, knockback_decay * delta)
		velocity = velocity.normalized() * (max_allowed_speed + excess_speed)

	# Perform movement
	move_and_slide()
	
	if is_melee and not is_repositioning:
		for i in get_slide_collision_count():
			var collision = get_slide_collision(i)
			var collider = collision.get_collider()
		
			if collider.is_in_group("player"):
				collider.take_damage(damage)
				
				# Trigger reposition state and retreat AWAY from the player
				is_repositioning = true
				reposition_timer = 0.0
				reposition_duration = randf_range(1.0, 3.0)
				select_reposition_target_away_from_player()
				break

func select_random_target() -> void:
	current_wander_delay = randf_range(1.0, 3.0)
	var random_angle := randf_range(0.0, PI * 2.0)
	var direction := Vector2.RIGHT.rotated(random_angle)
	target_position = global_position + (direction * 300.0)

func select_reposition_target_away_from_player() -> void:
	if player == null:
		select_random_target()
		return
		
	var away_dir := player.global_position.direction_to(global_position)
	var random_offset := randf_range(-PI / 4.0, PI / 4.0)
	away_dir = away_dir.rotated(random_offset)
	
	target_position = global_position + (away_dir * 250.0)

func get_spot_near_player() -> Vector2:
	var random_angle := randf_range(0.0, PI * 2.0)
	var random_distance := randf_range(150.0, 250.0)
	var offset := Vector2.RIGHT.rotated(random_angle) * random_distance
	return player.global_position + offset

func _on_vision_area_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		is_player_in_range = true
		target_position = Vector2.ZERO 

func _on_vision_area_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		is_player_in_range = false
		select_random_target()
		wander_timer = 0.0
		
func take_damage(damage : float, damage_pos : Vector2):
	health -= damage
	if health <= 0.0:
		if death_sound.get_parent():
			death_sound.get_parent().remove_child(death_sound)
		get_tree().current_scene.add_child(death_sound)
		death_sound.play()
		death_sound.finished.connect(death_sound.queue_free)
		queue_free()
	else:
		knock_back_enemy(damage_pos)
		
func knock_back_enemy(attacker_position : Vector2):
	# Fixed: Knockback direction should point AWAY from the attacker (- to +)
	var direction = (global_position - attacker_position).normalized()
	velocity += direction * knockback_force
