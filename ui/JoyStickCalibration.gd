extends Node2D

const size = 256

#onready var calibration_circle = $CalibrationCircle
#onready var stickpos_l = $CalibrationCircle/StickPos_Left
#onready var stickpos_r = $CalibrationCircle/StickPos_Right

onready var raw_left_stick = $Raw_Input/Left/StickPos
onready var left_stick_line = $Raw_Input/Left/Line2D
onready var left_stick_data = $Raw_Input/Left/Data

onready var raw_right_stick = $Raw_Input/Right/StickPos
onready var right_stick_line = $Raw_Input/Right/Line2D
onready var right_stick_data = $Raw_Input/Right/Data

func _process(_t:float) -> void:

#	if pos.length() > 1.0:
#		pos = pos.normalized()
	
#	stickpos_l.position = pos * size
	#stickpos_r.position = Game.get_stick_input("right") * size
#	calibration_circle.material.set_shader_param("outer_deadzone", Game.joystick_outer_deadzone)
#	calibration_circle.material.set_shader_param("inner_deadzone", Game.joystick_inner_deadzone)

	var x_str:String
	var y_str:String
	var length_str:String

	var pos_left = Vector2(Input.get_joy_axis(0, 0), Input.get_joy_axis(0, 1))
	var length_left = pos_left.length()
	raw_left_stick.position = pos_left * 127
	left_stick_line.points = PoolVector2Array([Vector2(0,0), raw_left_stick.position])
	x_str = sign_as_string(pos_left.x) + str(abs(pos_left.x)).pad_decimals(3)
	y_str = sign_as_string(pos_left.y) + str(abs(pos_left.y)).pad_decimals(3)
	length_str = str(length_left).pad_decimals(3)
	left_stick_data.bbcode_text = '[center][color=#ff8080]X ' + x_str + '[/color] | [color=#80ff80]Y ' + y_str + '[/color] | [color=#8080ff]Length ' + length_str + '[/color][/center]'
	
	var pos_right = Vector2(Input.get_joy_axis(0, 2), Input.get_joy_axis(0, 3))
	var length_right = pos_right.length()
	raw_right_stick.position = pos_right * 127
	right_stick_line.points = PoolVector2Array([Vector2(0,0), raw_right_stick.position])
	x_str = sign_as_string(pos_right.x) + str(abs(pos_right.x)).pad_decimals(3)
	y_str = sign_as_string(pos_right.y) + str(abs(pos_right.y)).pad_decimals(3)
	length_str = str(length_right).pad_decimals(3)
	right_stick_data.bbcode_text = '[center][color=#ff8080]X ' + x_str + '[/color] | [color=#80ff80]Y ' + y_str + '[/color] | [color=#8080ff]Length ' + length_str + '[/color][/center]'

func sign_as_string(number:float):
	match sign(number):
		-1.0 : return "−"
		0.0  : return "±"
		1.0  : return "+"
