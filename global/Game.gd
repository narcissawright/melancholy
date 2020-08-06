extends Node

onready var melanie = preload("res://actor/melanie/Melanie.tscn")
#onready var melancholy = preload("res://player/Melancholy.tscn")
onready var cam = preload("res://camera/Camera.tscn")
onready var ui = preload("res://ui/UI.tscn")
var current_character:String = "Melanie"
var player:Node

var time_of_day:float = 540.0
var timescale:float = 1.0

const GRAVITY:float = -20.0

func _init() -> void:
	OS.window_position = Vector2(172, 30) # so it shows up on my monitor in a comfy spot
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

func _physics_process(t) -> void:
	if not get_tree().paused:
		time_of_day = fmod(time_of_day + t * timescale, 1440.0)
		Debug.text.write("Time of day: " + str(time_of_day))
	
	if Input.is_action_just_pressed("ui_cancel"):
		get_tree().quit()
	if Input.is_action_just_pressed("fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = not get_tree().paused
		Events.emit_signal("pause", get_tree().paused)

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
