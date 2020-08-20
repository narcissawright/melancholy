extends Node2D

"""
Need to figure out a full list of all available button assignments

- Target or Reset Camera (either, depending on context)
- Target
- Reset Camera

- Jump
- Primary Attack
- Subweapon
- Interact
- Shield

- Scroll Items Right
- Scroll Items Left
- Use Item

- Pause (maybe cannot be remapped?)

- First Person

- Move (Stick Only)
- Rotate Camera (Stick Only ?)

- Move Up
- Move Down
- Move Left
- Move Right
- Custom move value
"""


"""
Additionally, I want to figure out what exact options will be available for control stick customization

- Outer deadzone
- Inner deadzone
- Ramp
- Digital Notches
"""


"""
Finally, I want to have other options:

- Invert X axis (Right Stick, also first person?)
- Invert Y axis (Right Stick, also first person?)
- Camera Zoom
- Show/Hide UI
- Show/Hide contextual button prompt?
- Rounded screen corners ON/OFF
"""

# Tween
onready var tween = $Tween
onready var color_pressed = Color("597dce")

var controller:Dictionary

func _ready() -> void:
	visible = false
	
	controller = {
		"ZR": {
			"button": $ControllerButtons/ZR,
			"action": $ActionLabels/ZR,
			"label":  $ActionLabels/ZR/Label },
		"ZL": {
			"button": $ControllerButtons/ZL,
			"action": $ActionLabels/ZL,
			"label":  $ActionLabels/ZL/Label },
		"R": {
			"button": $ControllerButtons/R,
			"action": $ActionLabels/R, 
			"label":  $ActionLabels/R/Label },
		"L": {
			"button": $ControllerButtons/L,
			"action": $ActionLabels/L, 
			"label":  $ActionLabels/L/Label },
		"A": {
			"button": $ControllerButtons/A,
			"action": $ActionLabels/A,
			"label":  $ActionLabels/A/Label },
		"B": {
			"button": $ControllerButtons/B,
			"action": $ActionLabels/B,
			"label":  $ActionLabels/B/Label },
		"X": {
			"button": $ControllerButtons/X,
			"action": $ActionLabels/X,
			"label":  $ActionLabels/X/Label },
		"Y": {
			"button": $ControllerButtons/Y,
			"action": $ActionLabels/Y,
			"label":  $ActionLabels/Y/Label },
		"d-up": {
			"button": $ControllerButtons/D_Up,
			"action": $ActionLabels/D_Up,
			"label":  $ActionLabels/D_Up/Label },
		"d-down": {
			"button": $ControllerButtons/D_Down,
			"action": $ActionLabels/D_Down,
			"label":  $ActionLabels/D_Down/Label },
		"d-left": {
			"button": $ControllerButtons/D_Left,
			"action": $ActionLabels/D_Left,
			"label":  $ActionLabels/D_Left/Label },
		"d-right": {
			"button": $ControllerButtons/D_Right,
			"action": $ActionLabels/D_Right,
			"label":  $ActionLabels/D_Right/Label },
		"select": {
			"button": $ControllerButtons/Select,
			"action": $ActionLabels/Select,
			"label":  $ActionLabels/Select/Label },
		"start": {
			"button": $ControllerButtons/Start,
			"action": $ActionLabels/Start,
			"label":  $ActionLabels/Start/Label },
		"L3": {
			"button": $ControllerButtons/Left_Stick,
			"action": $ActionLabels/L3,
			"label":  $ActionLabels/L3/Label },
		"R3": {
			"button": $ControllerButtons/Right_Stick,
			"action": $ActionLabels/R3,
			"label":  $ActionLabels/R3/Label },
		"left_stick": {
			"button": $ControllerButtons/Left_Stick,
			"action": $ActionLabels/Left_Stick,
			"label":  $ActionLabels/Left_Stick/Label,
			"pressed": false },
		"right_stick": {
			"button": $ControllerButtons/Right_Stick,
			"action": $ActionLabels/Right_Stick,
			"label":  $ActionLabels/Right_Stick/Label,
			"pressed": false }
		}

func update_pressed(key:String, pressed:bool) -> void:
	if pressed:
		if key != "left_stick" and key != "right_stick":
			# Only flash the control stick when clicking it.
			controller[key].button.frame = 1
			tween.interpolate_property(controller[key].button, 
				"modulate", Color(1,1,1,1), color_pressed, 0.2)
		tween.interpolate_property(controller[key].action, 
			"self_modulate", color_pressed, Color("30346d"), 0.2)
		controller[key].action.get_node("Label").set("custom_colors/font_color", Color("ffffff"))
		tween.start()
	else:
		controller[key].button.frame = 0
		tween.stop(controller[key].button)
		tween.stop(controller[key].action)
		tween.stop(controller[key].action.get_node("Label"))
		controller[key].button.modulate = Color(1,1,1)
		controller[key].action.self_modulate = Color("151515")
		controller[key].action.get_node("Label").set("custom_colors/font_color", Color("a9b8b4"))

func _process(_t:float) -> void:
	if not visible: # use a better check here
		return
	
	# Check for button presses
	for key in controller:
		if Input.is_action_just_pressed(key):
			update_pressed(key, true)
		elif Input.is_action_just_released(key):
			update_pressed(key, false)
	
	# Check for stick movement
	var left_stick_pos = Game.get_stick_input("left")
	var right_stick_pos = Game.get_stick_input("right")
	
	controller["left_stick"].button.position = left_stick_pos * 35.0
	controller["right_stick"].button.position = right_stick_pos * 35.0
	
	if not controller["left_stick"].pressed and left_stick_pos != Vector2.ZERO:
		controller["left_stick"].pressed = true
		update_pressed("left_stick", true)
	elif controller["left_stick"].pressed and left_stick_pos == Vector2.ZERO:
		controller["left_stick"].pressed = false
		update_pressed("left_stick", false)
		
	if not controller["right_stick"].pressed and right_stick_pos != Vector2.ZERO:
		controller["right_stick"].pressed = true
		update_pressed("right_stick", true)
	elif controller["right_stick"].pressed and right_stick_pos == Vector2.ZERO:
		controller["right_stick"].pressed = false
		update_pressed("right_stick", false)
