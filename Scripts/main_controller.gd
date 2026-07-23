extends Node2D

var grenade_inventory: Array[base_grenade] = []
var round_num := 1
var num_grenades := 5
var num_rooms := 5
var currently_selected_grenade_index = 0

var grenades_been_edited : Array[bool] = []


@export var player : CharacterBody2D
@export var controller_camera : Camera2D
@export var player_camera : Camera2D
@export var grenade_launcher : Node2D
@export var list_of_grenades_to_choose_from : Array[PackedScene]
@export var grenade_spawn_pos : Node2D

#ui stuff
@onready var seconds_slider : HSlider = %HSlider
@onready var forward : Button = %Forward
@onready var backward : Button = %Back
@onready var play : Button = %Play
@onready var grenade_type : Label = %GrenadeType
@onready var seconds_label : Label = %Seconds
@onready var edit_to_play : Label = %EditToPlayText
@onready var planning_mode_canvas : CanvasLayer = %PlanningCanvas




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
	
	seconds_slider.value = grenade_inventory[currently_selected_grenade_index].detonate_cooldown
	
	for i in range(num_grenades):
		grenades_been_edited.append(false)
	
	seconds_slider.value_changed.connect(_on_slider_value_changed)
	
	forward.pressed.connect(_on_button_pressed_forward)
	backward.pressed.connect(_on_button_pressed_back)
	play.pressed.connect(_on_button_pressed_play)
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if current_state == State.PLANNING:
		grenade_type.text = grenade_inventory[currently_selected_grenade_index].grenade_name
	
	if currently_selected_grenade_index == 0:
		backward.disabled = true
	else:
		backward.disabled = false
		
	if currently_selected_grenade_index == num_grenades - 1:
		forward.disabled = true
	else:
		forward.disabled = false
	
	if current_state == State.PLANNING:
		grenade_inventory[currently_selected_grenade_index].visible = true
	
	if current_state == State.PLANNING:
		for bullet in grenade_inventory:
			bullet.global_position = grenade_spawn_pos.global_position
	


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
			planning_mode_canvas.visible = true
			#workbench_ui.show()
	
		State.ACTION:
			#grenade_launcher
			Engine.time_scale = 1.0
			player_camera.make_current()
			planning_mode_canvas.visible = false
			# Start timers on ALL grenades simultaneously when action starts
			for grenade in grenade_inventory:
				if is_instance_valid(grenade):
					grenade.start_countdown()
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
	for i in range(num_grenades):
		var new_grenade = list_of_grenades_to_choose_from.pick_random() .instantiate()
		# 2. Set its position
		new_grenade.global_position = grenade_spawn_pos.global_position
		
		# 3. Add it to the active game world
		add_child(new_grenade)
		grenade_inventory.append(new_grenade)
		
	grenade_launcher.get_grenades(grenade_inventory)
	
	
	
#UI functions	
func _on_slider_value_changed(new_value: float) -> void:
	# Update the variable
	grenade_inventory[currently_selected_grenade_index].detonate_cooldown = new_value
	
	# Update the text label (str() converts the number to text)
	seconds_label.text =  str(new_value) 
	
	grenades_been_edited[currently_selected_grenade_index] = true
	
	var x := 0
	for i in range(num_grenades):
		if grenades_been_edited[i]:
			x += 1
	if x == num_grenades:
		play.disabled = false
		edit_to_play.text = ""
	
func _on_button_pressed_forward():
	currently_selected_grenade_index += 1
	seconds_slider.value = grenade_inventory[currently_selected_grenade_index].detonate_cooldown
	grenade_inventory[currently_selected_grenade_index].visible = true
	grenade_inventory[currently_selected_grenade_index - 1].visible = false
	print(grenade_inventory[currently_selected_grenade_index].global_position)

func _on_button_pressed_back():
	currently_selected_grenade_index -= 1 
	seconds_slider.value = grenade_inventory[currently_selected_grenade_index].detonate_cooldown
	grenade_inventory[currently_selected_grenade_index].visible = true
	grenade_inventory[currently_selected_grenade_index + 1].visible = false
	
func _on_button_pressed_play():
	change_state(State.ACTION)
