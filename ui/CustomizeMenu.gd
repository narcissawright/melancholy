extends "res://ui/MenuClass.gd"

enum { BUTTON_MAPPING, JOYSTICK_CALIBRATION }

func _init():
	menu_items = ["Button Mapping", "Joystick Calibration"]

func _return_pressed() -> void:
	current_menu_index = 0
	stop()
	Game.ui.paused.change_state("main_menu")
	
func _menu_item_select(index):
	match index:
		BUTTON_MAPPING:
			print("button_mapping")
		JOYSTICK_CALIBRATION:
			print("joystick_calibration")
