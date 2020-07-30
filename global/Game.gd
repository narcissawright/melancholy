extends Node

onready var player = preload("res://player/Melanie.tscn")
onready var cam = preload("res://player/Camera.tscn")

const GRAVITY:float = -20.0

func _init() -> void:
	OS.window_position = Vector2(172, 160) # so it shows up on my monitor in a comfy spot

func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS # Run this script while paused
	
	# Instance and add nodes.
	player = player.instance()
	cam = cam.instance()
	add_child(player)
	add_child(cam)

func _input(event: InputEvent) -> void:
	if event.is_action("ui_cancel"):
		get_tree().quit()
	if Input.is_action_just_pressed("fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = not get_tree().paused

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
