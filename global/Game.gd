extends Node

onready var melanie = preload("res://player/melanie/Melanie.tscn")
onready var cam = preload("res://camera/Camera.tscn")
onready var ui = preload("res://ui/UI.tscn")
var current_character:String = "Melanie"
var player:Node

var frame_time:float = 1.0 / 60.0
var time_of_day:float = 540.0
var timescale:float = 1

const GRAVITY:float = -20.0

var joystick_outer_threshold = 0.9
var joystick_axis_deadzone = 0.15
#var joystick_easing_curve = 2.0

func _init() -> void:
	OS.window_position = Vector2(172, 30) # so it shows up on my monitor in a comfy spot
	OS.window_size = Vector2(1280, 720)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS # Run this script while paused
	
	# Some kind of load save data thing here
	pass
	
	# Instance player character
	match current_character:
		"Melanie":
			player = melanie.instance()
	
	# Instance scenes
	cam = cam.instance()
	ui = ui.instance()
	
	# Add nodes.
	add_child(player)
	add_child(cam)
	add_child(ui)

func time_readable (time:float) -> String:
	var hours:int
	var minutes:int
	var am:bool = true
# warning-ignore:integer_division
	hours = int(time) / 60
	if hours >= 12: 
		hours -= 12
		am = false
	if hours == 0: hours = 12
	minutes = int(time) % 60
	
	var time_string:String = str(hours).pad_zeros(2)
	time_string += ":"
	time_string += str(minutes).pad_zeros(2)
	time_string += " "
	time_string += "AM" if am else "PM"
	return time_string

func _physics_process(t) -> void:
	if not get_tree().paused:
		time_of_day = fmod(time_of_day + t * timescale, 1440.0)
		Debug.text.write("Time of day: " + time_readable(time_of_day))
	
	if Input.is_action_just_pressed("ui_cancel"):
		quit_game()
	if Input.is_action_just_pressed("fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
	if Input.is_action_just_pressed("pause"):
		unpause()

func unpause() -> void:
	get_tree().paused = not get_tree().paused
	Events.emit_signal("pause", get_tree().paused)

func quit_game() -> void:
	get_tree().quit()

func get_stick_input(which:String) -> Vector2:
	"""
	this function takes in 'left' or 'right'
	referring to the left and right control sticks on the joypad
	it returns an altered input that accounts for deadzones.
	"""
	# get raw input
	var axes:Vector2
	if which == 'left':
		axes = Vector2(Input.get_joy_axis(0, 0), Input.get_joy_axis(0, 1))
	elif which == 'right':
		axes = Vector2(Input.get_joy_axis(0, 2), Input.get_joy_axis(0, 3))

	if abs(axes.x) < joystick_axis_deadzone:
		axes.x = 0.0
	if abs(axes.y) < joystick_axis_deadzone:
		axes.y = 0.0
		if axes.x == 0.0:
			return Vector2.ZERO # No input.
	
	var length = axes.length()
	var normalized = axes.normalized()
	
	if length > joystick_outer_threshold:
		return normalized # Max input
	
	var percentage = inverse_lerp(joystick_axis_deadzone, joystick_outer_threshold, length)
#	percentage = pow(percentage, joystick_easing_curve)
	return normalized * percentage
