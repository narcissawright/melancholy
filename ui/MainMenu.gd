extends "res://ui/MenuClass.gd"

enum { RESUME, CUSTOMIZE, FREE_CAMERA, QUIT_GAME }

func _init():
	menu_items = ["Resume", "Customize", "Free Camera", "Quit Game"]

func _return_pressed() -> void:
	if about_to_quit():
		update_menu_items() # Rewrites the text (undoes the Are you sure?)
	else:
		Game.unpause()

func about_to_quit() -> bool:
	return menu.get_child(QUIT_GAME).text != menu_items[QUIT_GAME]
		
func _menu_item_selected(index):
	match index:
		RESUME:
			Game.unpause()
		CUSTOMIZE:
			Game.ui.paused.change_state("customize_menu")
			stop()
		FREE_CAMERA:
			Game.ui.paused.change_state("free_camera")
			stop()
		QUIT_GAME:
			if about_to_quit():
				Game.quit_game()
			else:
				menu.get_child(QUIT_GAME).text = "Quit Game? Are you sure?"
