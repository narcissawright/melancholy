extends Node2D

"""
To do:
	- code cleanup
	- slight blur of the 3d world or something when paused
	- sfx
	- customize (options and stuff)
	- are you sure you want to quit?
"""

onready var pause_menu = $PauseMenu

enum { RESUME, CUSTOMIZE, FREE_CAMERA, QUIT_GAME }
var current_menu_index = RESUME
var time = 0.0

var menu_items = ["Resume", "Customize", "Free Camera", "Quit Game"]

var selected = Color(1, 1, 0.4, 1)
var unselected = Color('a9b8b4')

func _ready() -> void:
	visible = false
	Events.connect("pause", self, "pause_state_changed")
	
func pause_state_changed(state:bool) -> void:
	visible = state
	if state == true:
		current_menu_index = RESUME
		time = 0.0
		update_menu_items()

func update_menu_items() -> void:
	for i in pause_menu.get_child_count():
		var menu_item = pause_menu.get_child(i)
		menu_item.text = ">  " + menu_items[i] + "  <" if i == current_menu_index else menu_items[i]
		menu_item.modulate = selected if i == current_menu_index else unselected

func _process(t:float) -> void:
	if visible:
		var prior_menu_index = current_menu_index
		
		if Input.is_action_just_pressed("B"):
			Game.unpause()
		elif Input.is_action_just_pressed("ui_select"):
			match current_menu_index:
				RESUME:
					Game.unpause()
				CUSTOMIZE:
					pass
				FREE_CAMERA:
					Game.cam.enable_pause_controls()
					visible = false
				QUIT_GAME:
					# Are you sure?
					Game.quit_game()
		else:
			if Input.is_action_just_pressed("ui_down"):
				if current_menu_index < QUIT_GAME:
					current_menu_index += 1
				else:
					current_menu_index = RESUME
			if Input.is_action_just_pressed("ui_up"):
				if current_menu_index > RESUME:
					current_menu_index -= 1
				else:
					current_menu_index = QUIT_GAME
					
			# Update animated selected color
			time += t
			time = fmod(time, 0.5)
			var blue = 0.4 if time < 0.25 else 0.8
			selected = Color(1, 1, blue, 1)
			
			if current_menu_index != prior_menu_index:
				update_menu_items()
			else:
				pause_menu.get_child(current_menu_index).modulate = selected
				
