extends Node2D

"""
To do:
	- slight blur of the 3d world or something when paused?
	- sfx
"""

onready var darken = $Darken
onready var main_menu = $MainMenu
onready var customize = $InputDisplay
onready var ingame_ui = $"../InGame_UI"

func _ready() -> void:
	Events.connect("pause", self, "pause_state_changed")
	darken.visible = false
	
func pause_state_changed(paused:bool) -> void:
	if paused:
		darken.visible = true
		change_state("main_menu")
	else:
		darken.visible = false
		main_menu.stop()
		ingame_ui.visible = true

func exit_free_camera() -> void:
	darken.visible = true
	ingame_ui.visible = true
	Input.action_release("B")
	main_menu.start()

func change_state(state:String) -> void:
	match state:
		"main_menu":
			main_menu.start_fresh()
		"free_camera":
			Game.cam.enable_pause_controls()
			darken.visible = false
			ingame_ui.visible = false
			# display cam controls via ContextHint
