extends Node2D

var grenade_inventory: Array[base_grenade] = []
var round_num := 1
var num_grenades := 5
var num_rooms := 5

@export var player : CharacterBody2D
@export var controller_camera : Camera2D
@export var player_camera : Camera2D
@export var grenade_launcher : Node2D
@export var list_of_grenades_to_choose_from : Array[PackedScene]
@export var grenade_spawn_pos : Node2D


enum State {
	SETUP,      # Generating map, loading bench, time_scale = 0
	PLANNING,   # Player picking grenades and setting timers
	ACTION,     # Player camera active, shooting, time_scale = 1
	RESET       # Level complete, cleaning up before restarting
}

var current_state: State = State.SETUP


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	change_state(State.SETUP)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	


func change_state(new_state: State) -> void:
	current_state = new_state
	
	match current_state:
		State.SETUP:
			Engine.time_scale = 0.0
			controller_camera.make_current()
			generate_map()
			load_grenades_to_bench()
			change_state(State.PLANNING)
			
		State.PLANNING:
			Engine.time_scale = 0.0
			#workbench_ui.show()
			change_state(State.ACTION)
		State.ACTION:
			grenade_launcher
			Engine.time_scale = 1.0
			player_camera.make_current()
			#workbench_ui.hide()
			#hide_workbench_grenades()
			
		State.RESET:
			Engine.time_scale = 0.0
			clear_map()
			change_state(State.SETUP)

func _on_start_button_pressed():
	if current_state == State.PLANNING:
		change_state(State.ACTION)
		
func generate_map():
	pass

func clear_map():
	pass
	
func load_grenades_to_bench():
	for i in range(num_grenades - 1):
		var new_grenade = list_of_grenades_to_choose_from.pick_random() .instantiate()
		# 2. Set its position
		new_grenade.global_position = grenade_spawn_pos.global_position
		
		# 3. Add it to the active game world
		add_child(new_grenade)
		grenade_inventory.append(new_grenade)
		
	grenade_launcher.get_grenades(grenade_inventory)
		
