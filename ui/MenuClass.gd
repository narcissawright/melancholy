extends Node2D

onready var menu = $menu_items

var current_menu_index = 0
var time = 0.0

# This will be overwritten by the script that inherits this.
var menu_items:int = 0 # how many menu items are there?

var selected = Color(1, 1, 0.8, 1)
var unselected = Color('a9b8b4')

func _ready() -> void:
	stop()

func start() -> void:
	update_menu_items()
	visible = true
	set_process(true)

func stop() -> void:
	visible = false
	set_process(false)

func update_menu_items() -> void:
	time = 0.0
	for i in menu.get_child_count():
		var menu_item = menu.get_child(i)
		menu_item.self_modulate = selected if i == current_menu_index else unselected

# These functions are intended to be overwritten by the script that inherits this one.
func _return_pressed() -> void:
	print ("the player pressed the B button.");

func _menu_item_selected(index:int) -> void:
	print ("menu_item ", index, " selected.");

func _down_pressed() -> void:
	# Default behavior:
	current_menu_index = posmod(current_menu_index + 1, menu_items)

func _up_pressed() -> void:
	# Default behavior:
	current_menu_index = posmod(current_menu_index - 1, menu_items)

func _process(t:float) -> void:
	if Input.is_action_just_pressed("B"):
		_return_pressed()
	elif Input.is_action_just_pressed("ui_select"):
		_menu_item_selected(current_menu_index)
	else:
		var prior_menu_index = current_menu_index
		if Input.is_action_just_pressed("ui_down"):
			_down_pressed()
		if Input.is_action_just_pressed("ui_up"):
			_up_pressed()
		
		# Selected color
		time += t
		time = fmod(time, 0.6)
		var blue = 0.7 if time < 0.3 else 0.35
		selected = Color(1, 1, blue, 1)
		
		if current_menu_index != prior_menu_index:
			update_menu_items()
		else:
			menu.get_child(current_menu_index).self_modulate = selected
			
