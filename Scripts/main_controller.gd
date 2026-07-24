extends Node2D

var grenade_inventory: Array[base_grenade] = []
var round_num := 1
var num_grenades := 5
var num_rooms := 5
var currently_selected_grenade_index = 0

var grenades_been_edited : Array[bool] = []
var action_state = false

var time_elapsed := 0.0

var last_beep_second: int = -1  # Tracks the last second a beep was played


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
@onready var playing_mode_canvas : CanvasLayer = %GameplayCanvas
@onready var timer : Label = %CountdownTimer

@onready var beeping_sound : AudioStreamPlayer = %BeepingSound
@onready var health_bar : ProgressBar = %HealthBar



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
	
	health_bar.value = player.health
	
	time_elapsed += delta
	
	if grenade_inventory.size() > 0 and is_instance_valid(grenade_inventory[0]):
		# 1. Calculate the exact remaining time
		var time_left: float = grenade_inventory[0].detonate_cooldown - time_elapsed
		
		# 2. Display integer countdown using native ceil() (clamped to 0)
		var display_seconds: int = max(0, ceil(time_left))
		timer.text = str(display_seconds)
		
		# 3. Dynamic text colouring based on the 3-second threshold
		if time_left <= 3.0:
			timer.modulate = Color.RED
			
			# 4. Play the beep sound exactly once per second
			if display_seconds != last_beep_second and display_seconds > 0:
				beeping_sound.play()
				last_beep_second = display_seconds  # Lock this second
		else:
			timer.modulate = Color.WHITE
			last_beep_second = -1  # Reset track if time goes back up
	
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
			action_state = false
			
			
		State.PLANNING:
			Engine.time_scale = 0.0
			planning_mode_canvas.visible = true
			#workbench_ui.show()
	
		State.ACTION:
			sort_grenades()
			#grenade_launcher
			Engine.time_scale = 1.0
			player_camera.make_current()
			planning_mode_canvas.visible = false
			playing_mode_canvas.visible = true
			action_state = true
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
			action_state = false

func _on_start_button_pressed():
	if current_state == State.PLANNING:
		change_state(State.ACTION)
		
func generate_map():
	pass

func clear_map():
	pass
	
func load_grenades_to_bench():
	for i in range(num_grenades):
		var new_grenade = list_of_grenades_to_choose_from.pick_random().instantiate()
		new_grenade.global_position = grenade_spawn_pos.global_position
		add_child(new_grenade)
		grenade_inventory.append(new_grenade)
		
		
		new_grenade.exploded.connect(_on_grenade_exploded)
		
	
func sort_grenades():
	#  Sort the array using a custom lambda comparison function
	grenade_inventory.sort_custom(
		func(a, b): return a.detonate_cooldown < b.detonate_cooldown
	)
	
	grenade_launcher.get_grenades(grenade_inventory)
	
	print("--- Sorted Grenade Inventory ---")
	for i in range(grenade_inventory.size()):
		var grenade = grenade_inventory[i]
		print("Slot %d: %s (Cooldown: %.2f)" % [i, grenade.grenade_name, grenade.detonate_cooldown])
		
func _on_grenade_exploded(grenade_instance: base_grenade) -> void:
	# .erase() finds that specific grenade in the array and removes it.
	# This automatically shifts the next grenade to index 0!
	if grenade_inventory.has(grenade_instance):
		grenade_inventory.erase(grenade_instance)
		print("Grenade removed from list. Remaining: ", grenade_inventory.size())
	
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
	
