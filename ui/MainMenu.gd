extends Node2D

onready var pause_controller = get_parent()
onready var menu = $menu_items

enum { RESUME, CUSTOMIZE, FREE_CAMERA, QUIT_GAME }
var current_menu_index = RESUME
var time = 0.0

var menu_items = ["Resume", "Customize", "Free Camera", "Quit Game"]

var selected = Color(1, 1, 0.8, 1)
var unselected = Color('a9b8b4')

var about_to_quit = false

func start_fresh() -> void:
	current_menu_index = RESUME
	start()

func start() -> void:
	update_menu_items()
	visible = true
	set_process(true)

func stop() -> void:
	visible = false
	set_process(false)

func update_menu_items() -> void:
	time = 0.0
	about_to_quit = false
	for i in menu.get_child_count():
		var menu_item = menu.get_child(i)
		menu_item.text = ">  " + menu_items[i] + "  <" if i == current_menu_index else menu_items[i]
		menu_item.modulate = selected if i == current_menu_index else unselected

func _process(t:float) -> void:
	var prior_menu_index = current_menu_index
		
	if Input.is_action_just_pressed("B"):
		"""
		This triggers even when exiting from the pause camera
		because this code is running on the same frame..
		
		Need to find a way around that.
		"""
		
		if about_to_quit:
			update_menu_items() # goes back to prior state
		else:
			Game.unpause()
	elif Input.is_action_just_pressed("ui_select"):
		match current_menu_index:
			RESUME:
				Game.unpause()
			CUSTOMIZE:
				pass
				#customize.visible = not customize.visible
				#set_process(false)
			FREE_CAMERA:
				pause_controller.change_state("free_camera")
				stop()
			QUIT_GAME:
				if not about_to_quit:
					menu.get_child(QUIT_GAME).text = ">  Quit Game? Are you sure?  <"
					about_to_quit = true
				else:
					Game.quit_game()
	else:
		if Input.is_action_just_pressed("ui_down"):
			current_menu_index = posmod(current_menu_index + 1, 4)
		if Input.is_action_just_pressed("ui_up"):
			current_menu_index = posmod(current_menu_index - 1, 4)
		
		# Update animated selected color
		time += t
		time = fmod(time, 0.6)
		var blue = 0.7 if time < 0.3 else 0.35
		selected = Color(1, 1, blue, 1)
		
		if current_menu_index != prior_menu_index:
			update_menu_items()
		else:
			menu.get_child(current_menu_index).modulate = selected
			
