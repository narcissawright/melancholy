extends Node2D

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

func _ready() -> void:
	visible = false

func _process(_t:float) -> void:
	if not visible:
		return
		
	ZL.frame = int(Input.is_action_pressed("ZL"))
	ZR.frame = int(Input.is_action_pressed("ZR"))
	
	L.frame = int(Input.is_action_pressed("L"))
	R.frame = int(Input.is_action_pressed("R"))
	
	A.frame = int(Input.is_action_pressed("A"))
	B.frame = int(Input.is_action_pressed("B"))
	X.frame = int(Input.is_action_pressed("X"))
	Y.frame = int(Input.is_action_pressed("Y"))
	
	d_up.frame = int(Input.is_action_pressed("d-up"))
	d_down.frame = int(Input.is_action_pressed("d-down"))
	d_left.frame = int(Input.is_action_pressed("d-left"))
	d_right.frame = int(Input.is_action_pressed("d-right"))
	
	start.frame = int(Input.is_action_pressed("start"))
	select.frame = int(Input.is_action_pressed("select"))
	
	left_stick.frame = int(Input.is_action_pressed("L3"))
	right_stick.frame = int(Input.is_action_pressed("R3"))
	left_stick.position = Game.get_stick_input("left") * 30.0
	right_stick.position = Game.get_stick_input("right") * 30.0
	
