extends Node2D

"""
To do:
	- slight blur of the 3d world or something when paused?
	- sfx
"""

onready var darken = $Darken
onready var main_menu = $MainMenu
onready var customize_menu = $CustomizeMenu
onready var ingame_ui = $"../InGame_UI"

func _ready() -> void:
	Events.connect("pause", self, "pause_state_changed")
	darken.visible = false
	
func pause_state_changed(paused:bool) -> void:
	if paused:
		darken.visible = true
		main_menu.current_menu_index = 0
		change_state("main_menu")
	else:
		darken.visible = false
		main_menu.stop()
		customize_menu.stop()
		ingame_ui.visible = true

func exit_free_camera() -> void:
	darken.visible = true
	ingame_ui.visible = true
	Input.action_release("B")
	main_menu.start()

func change_state(state:String) -> void:
	match state:
		"main_menu":
			#ingame_ui.visible = true
			main_menu.start()
		"customize_menu":
			#ingame_ui.visible = false
			customize_menu.start()
		"free_camera":
			Game.cam.enable_pause_controls()
			darken.visible = false
			ingame_ui.visible = false
			# display cam controls via ContextHint
