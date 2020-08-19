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

static func get_stick_input(which:String) -> Vector2:
	"""
	this function takes in 'left' or 'right'
	referring to the left and right control sticks on the joypad
	it returns an altered input that accounts for deadzones and easing
	"""
	# get raw input
	var axes := Vector2()
	if which == 'left':
		axes = Vector2(Input.get_joy_axis(0, 0), Input.get_joy_axis(0, 1))
	elif which == 'right':
		axes = Vector2(Input.get_joy_axis(0, 2), Input.get_joy_axis(0, 3))

	# make input feel good
	var length:float = axes.length_squared()
	if length > 0.88: # upper limit
		return axes.normalized()
	elif length < 0.015: # lower limit
		return Vector2()
	axes = axes*axes.abs() # easing
	
	return axes
