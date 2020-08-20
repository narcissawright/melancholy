extends Node2D

# Tween
onready var tween = $Tween
onready var color_pressed = Color("597dce")

# Buttons
onready var ZR = $ZR_Button
onready var ZL = $ZL_Button
onready var L = $L_Button
onready var R = $R_Button
onready var A = $A_Button
onready var B = $B_Button
onready var Y = $Y_Button
onready var X = $X_Button
onready var left_stick = $Left_Stick
onready var right_stick = $Right_Stick
onready var d_up = $D_Up
onready var d_down = $D_Down
onready var d_left = $D_Left
onready var d_right = $D_Right
onready var start = $Start_Button
onready var select = $Select_Button

var node_action_pairs:Dictionary

func _ready() -> void:
	visible = false
	node_action_pairs = {
		ZR : "ZR",
		ZL : "ZL",
		L  : "L",
		R  : "R",
		A  : "A",
		B  : "B",
		X  : "X",
		Y  : "Y",
		left_stick  : "L3",
		right_stick : "R3",
		d_up    : "d-up",
		d_down  : "d-down",
		d_left  : "d-left",
		d_right : "d-right",
		start  : "start",
		select : "select"
	}

func update_pressed(button:Node, pressed:bool) -> void:
	if pressed:
		button.frame = 1
		tween.interpolate_property(button, "modulate", Color(1,1,1,1), color_pressed, 0.2)
		tween.start()
	else:
		button.frame = 0
		tween.stop(button)
		button.modulate = Color(1,1,1)

func _process(_t:float) -> void:
	if not visible:
		return
	
	for node in node_action_pairs:
		if Input.is_action_just_pressed(node_action_pairs[node]):
			update_pressed(node, true)
		elif Input.is_action_just_released(node_action_pairs[node]):
			update_pressed(node, false)
	
	left_stick.position = Game.get_stick_input("left") * 30.0
	right_stick.position = Game.get_stick_input("right") * 30.0
