extends Node2D

"""
To do:
	- slight blur of the 3d world or something when paused?
	- sfx
"""
 
onready var darken = $Darken
onready var main_menu = $MainMenu
onready var customize_menu = $CustomizeMenu
onready var input_display = $InputDisplay
onready var joystick_calibration = $JoystickCalibration
onready var ingame_ui = $"../InGame_UI"
onready var tween = $Tween
var tween_time = 0.1
var current_state = "unpaused"

func _ready() -> void:
	Events.connect("pause", self, "pause_state_changed")
	darken.modulate = Color(1,1,1,0);
	
func pause_state_changed(paused:bool) -> void:
	if paused:
		tween.interpolate_property(darken, "modulate:a", null, 1.0, tween_time)
		tween.interpolate_property(main_menu, "modulate:a", 0.0, 1.0, tween_time)
		change_state("main_menu")
	else:
		tween.interpolate_property(darken, "modulate:a", null, 0.0, tween_time)
		tween.interpolate_property(ingame_ui, "modulate:a", null, 1.0, tween_time)
		tween.start()
		stop(current_state)
	
func exit_free_camera() -> void:
	# Called externally (from Camera.gd)
	tween.interpolate_property(darken, "modulate:a", null, 1.0, tween_time)
	tween.interpolate_property(main_menu, "modulate:a", 0.0, 1.0, tween_time)
	Input.action_release("B")
	change_state("main_menu")

func change_state(state:String) -> void:
	current_state = state
	match state:
		"main_menu":
			tween.interpolate_property(ingame_ui, "modulate:a", null, 1.0, tween_time)
			tween.start()
			main_menu.start()
		"customize_menu":
			tween.interpolate_property(ingame_ui, "modulate:a", null, 0.0, tween_time)
			tween.start()
			customize_menu.start()
		"free_camera":
			Game.cam.enable_pause_controls()
			# todo: display cam controls via ContextHint
			tween.interpolate_property(darken, "modulate:a", null, 0.0, tween_time)
			tween.interpolate_property(ingame_ui, "modulate:a", null, 0.0, tween_time)
			tween.start()
		"button_mapping":
			input_display.start()
		"joystick_calibration":
			joystick_calibration.start()

func stop(state) -> void:
	current_state = "unpaused"
	match state:
		"main_menu":
			main_menu.stop()
			main_menu.current_menu_index = 0
		"customize_menu":
			customize_menu.stop()
			customize_menu.current_menu_index = 0
		"button_mapping":
			input_display.stop()
		"joystick_calibration":
			joystick_calibration.stop()
			joystick_calibration.current_menu_index = 0
