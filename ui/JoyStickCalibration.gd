extends Node2D

const size = 256
const greyed_out:String = "404040"

#onready var calibration_circle = $CalibrationCircle
#onready var stickpos_l = $CalibrationCircle/StickPos_Left
#onready var stickpos_r = $CalibrationCircle/StickPos_Right

onready var left_stick_pos:Sprite = $Raw_Input/Left/StickPos
onready var left_stick_x:Line2D = $Raw_Input/Left/X
onready var left_stick_y:Line2D = $Raw_Input/Left/Y
onready var left_stick_length:Line2D = $Raw_Input/Left/Length
onready var left_stick_data:RichTextLabel = $Raw_Input/Left/Data

onready var right_stick_pos:Sprite = $Raw_Input/Right/StickPos
onready var right_stick_x:Line2D = $Raw_Input/Right/X
onready var right_stick_y:Line2D = $Raw_Input/Right/Y
onready var right_stick_length:Line2D = $Raw_Input/Right/Length
onready var right_stick_data:RichTextLabel = $Raw_Input/Right/Data

func _process(_t:float) -> void:

#	if pos.length() > 1.0:
#		pos = pos.normalized()
	
#	stickpos_l.position = pos * size
	#stickpos_r.position = Game.get_stick_input("right") * size
#	calibration_circle.material.set_shader_param("outer_deadzone", Game.joystick_outer_deadzone)
#	calibration_circle.material.set_shader_param("inner_deadzone", Game.joystick_inner_deadzone)

	var pos:Vector2
	var length:float
	var visual_pos:Vector2
	var x_str:String
	var y_str:String
	var length_str:String
	var x_color:String
	var y_color:String
	var length_color:String
	
	##      ######  ######  ######
	##      ##      ##        ##
	##      #####   #####     ##
	##      ##      ##        ##
	######  ######  ##        ##
	
	pos = Vector2(Input.get_joy_axis(0, 0), Input.get_joy_axis(0, 1)) # Get data from control stick
	length = pos.length() # Find length
	visual_pos = pos * 127 # Sprite position
	left_stick_pos.position = visual_pos # Set sprite pos
	
	# set colors
	x_color = greyed_out if pos.x == 0.0 else "ff8080"
	y_color = greyed_out if pos.y == 0.0 else "80ff80"
	length_color = greyed_out if length == 0.0 else "8080ff"
	
	# set x line properties
	left_stick_x.points = PoolVector2Array([Vector2(visual_pos.x,-126), Vector2(visual_pos.x, 126)]) # set x axis line points
	left_stick_x.default_color = Color(x_color)
	
	# set y line properties
	left_stick_y.points = PoolVector2Array([Vector2(-126,visual_pos.y), Vector2(126, visual_pos.y)]) # set y axis line points
	left_stick_y.default_color = Color(y_color)

	# set length line properties
	left_stick_length.points = PoolVector2Array([Vector2(0,0), visual_pos]) # set length line points
	left_stick_length.default_color = Color(length_color)
	
	# create data string
	x_str = sign_as_string(pos.x) + str(abs(pos.x)).pad_decimals(3) # format x position as string
	y_str = sign_as_string(pos.y) + str(abs(pos.y)).pad_decimals(3) # format y position as string
	length_str = str(length).pad_decimals(3) # format length as string
	
	# apply data string
	left_stick_data.bbcode_text = '[center][color=#' + x_color + ']X ' + x_str + '[/color] | [color=#' + y_color +']Y ' + y_str + '[/color] | [color=#' + length_color + ']Length ' + length_str + '[/color][/center]'
	
	#####   ##   #####  ##  ##  ######
	##  ##  ##  ##      ##  ##    ##
	#####   ##  ## ###  ######    ##
	##  ##  ##  ##  ##  ##  ##    ##
	##  ##  ##   ####   ##  ##    ##
	
	pos = Vector2(Input.get_joy_axis(0, 2), Input.get_joy_axis(0, 3)) # Get data from control stick
	length = pos.length() # Find length
	visual_pos = pos * 127 # Sprite position
	right_stick_pos.position = visual_pos # Set sprite pos
	
	# set colors
	x_color = greyed_out if pos.x == 0.0 else "ff8080"
	y_color = greyed_out if pos.y == 0.0 else "80ff80"
	length_color = greyed_out if length == 0.0 else "8080ff"
	
	# set x line properties
	right_stick_x.points = PoolVector2Array([Vector2(visual_pos.x,-126), Vector2(visual_pos.x, 126)]) # set x axis line points
	right_stick_x.default_color = Color(x_color)
	
	# set y line properties
	right_stick_y.points = PoolVector2Array([Vector2(-126,visual_pos.y), Vector2(126, visual_pos.y)]) # set y axis line points
	right_stick_y.default_color = Color(y_color)

	# set length line properties
	right_stick_length.points = PoolVector2Array([Vector2(0,0), visual_pos]) # set length line points
	right_stick_length.default_color = Color(length_color)
	
	# create data string
	x_str = sign_as_string(pos.x) + str(abs(pos.x)).pad_decimals(3) # format x position as string
	y_str = sign_as_string(pos.y) + str(abs(pos.y)).pad_decimals(3) # format y position as string
	length_str = str(length).pad_decimals(3) # format length as string
	
	# apply data string
	right_stick_data.bbcode_text = '[center][color=#' + x_color + ']X ' + x_str + '[/color] | [color=#' + y_color +']Y ' + y_str + '[/color] | [color=#' + length_color + ']Length ' + length_str + '[/color][/center]'
	
func sign_as_string(number:float):
	match sign(number):
		-1.0 : return "−"
		0.0  : return "±"
		1.0  : return "+"
