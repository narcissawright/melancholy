extends "res://ui/MenuClass.gd"

enum { RESUME, CUSTOMIZE, FREE_CAMERA, QUIT_GAME }

func _init():
	menu_items = 4

func _return_pressed() -> void:
	if about_to_quit():
		update_menu_items() # Rewrites the text (undoes the Are you sure?)
	else:
		Events.emit_signal("unpause_game")

func _up_pressed() -> void:
	if current_menu_index == QUIT_GAME:
		menu.get_child(QUIT_GAME).text = "Quit Game"
	._up_pressed()
func _down_pressed() -> void:
	if current_menu_index == QUIT_GAME:
		menu.get_child(QUIT_GAME).text = "Quit Game"
	._down_pressed()

func about_to_quit() -> bool:
	return menu.get_child(QUIT_GAME).text != "Quit Game"

func _menu_item_selected(index):
	match index:
		RESUME:
			Events.emit_signal("unpause_game")
		CUSTOMIZE:
			UI.paused.change_state("customize_menu")
			stop()
		FREE_CAMERA:
			UI.paused.change_state("free_camera")
			stop()
		QUIT_GAME:
			if about_to_quit():
				Events.emit_signal("quit_game")
			else:
				menu.get_child(QUIT_GAME).text = "Quit Game? Are you sure?"
