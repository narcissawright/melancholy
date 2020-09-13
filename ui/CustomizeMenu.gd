extends "res://ui/MenuClass.gd"

enum { BUTTON_MAPPING, JOYSTICK_CALIBRATION }

func _init():
	menu_items = ["Button Mapping", "Joystick Calibration"]

func _return_pressed() -> void:
	current_menu_index = 0
	stop()
	UI.paused.change_state("main_menu")
	
func _menu_item_selected(index):
	match index:
		BUTTON_MAPPING:
			UI.paused.change_state("button_mapping")
			stop()
		JOYSTICK_CALIBRATION:
			UI.paused.change_state("joystick_calibration")
			stop()
