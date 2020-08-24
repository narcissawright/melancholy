extends "res://ui/MenuClass.gd"

"""
Phew, lots here, might wanna offload some of it to smaller scripts on individual nodes,
such as the node that activates the sliders and sets those colors??
"""

const size = 256
var greyed_out:String = "505050"

# Visualizer Nodes

onready var raw_left_shader_material = $Raw_Input/Left/Deadzone.material
onready var raw_left_stick_pos:Sprite = $Raw_Input/Left/StickPos
onready var raw_left_stick_x:Line2D = $Raw_Input/Left/X
onready var raw_left_stick_y:Line2D = $Raw_Input/Left/Y
onready var raw_left_stick_length:Line2D = $Raw_Input/Left/Length
onready var raw_left_stick_data:RichTextLabel = $Raw_Input/Left/Data

onready var raw_right_shader_material = $Raw_Input/Right/Deadzone.material
onready var raw_right_stick_pos:Sprite = $Raw_Input/Right/StickPos
onready var raw_right_stick_x:Line2D = $Raw_Input/Right/X
onready var raw_right_stick_y:Line2D = $Raw_Input/Right/Y
onready var raw_right_stick_length:Line2D = $Raw_Input/Right/Length
onready var raw_right_stick_data:RichTextLabel = $Raw_Input/Right/Data

onready var final_left_stick_pos:Sprite = $Final_Input/Left/StickPos
onready var final_left_stick_x:Line2D = $Final_Input/Left/X
onready var final_left_stick_y:Line2D = $Final_Input/Left/Y
onready var final_left_stick_length:Line2D = $Final_Input/Left/Length
onready var final_left_stick_data:RichTextLabel = $Final_Input/Left/Data
onready var final_left_stick_datadesc:RichTextLabel = $Final_Input/Left/DataDesc

onready var final_right_stick_pos:Sprite = $Final_Input/Right/StickPos
onready var final_right_stick_x:Line2D = $Final_Input/Right/X
onready var final_right_stick_y:Line2D = $Final_Input/Right/Y
onready var final_right_stick_length:Line2D = $Final_Input/Right/Length
onready var final_right_stick_data:RichTextLabel = $Final_Input/Right/Data
onready var final_right_stick_datadesc:RichTextLabel = $Final_Input/Right/DataDesc

# Outer Threshold

" Game.joystick_outer_threshold is the actual value "
const outer_threshold_default:float = 0.9
const outer_threshold_minimum:float = 0.5
var outer_threshold_prior_value:float = 0.9
onready var outer_threshold_color_rect_bg = $menu_items/OuterThreshold/BG
onready var outer_threshold_color_rect = $menu_items/OuterThreshold/Visual
onready var outer_threshold_value_label = $menu_items/OuterThreshold/Numerical

# Axis Deadzone

" Game.joystick_axis_deadzone is the actual value "
const axis_deadzone_default:float = 0.15
const axis_deadzone_maximum:float = 0.35
var axis_deadzone_prior_value:float = 0.15
onready var axis_deadzone_color_rect_bg = $menu_items/AxisDeadzone/BG
onready var axis_deadzone_color_rect = $menu_items/AxisDeadzone/Visual
onready var axis_deadzone_value_label = $menu_items/AxisDeadzone/Numerical

# Easing Curve
#" Game.joystick_easing_curve is the actual value "
#const easing_curve_default:float = 2.0
#const easing_curve_minimum:float = 0.125
#const easing_curve_maximum:float = 8.0
#var easing_curve_prior_value:float = 2.0
#onready var easing_curve_color_rect_bg = $menu_items/EasingCurve/BG
#onready var easing_curve_color_rect = $menu_items/EasingCurve/Visual
#onready var easing_curve_value_label = $menu_items/EasingCurve/Numerical

# Menu items

enum { OUTER_THRESHOLD, AXIS_DEADZONE, RESET_TO_DEFAULT }
var slider_controls_enabled:bool = false
const slider_width:float = 200.0 # pixels.
onready var descriptions = $Descriptions

func _init() -> void:
	menu_items = ["Outer Threshold", "Axis Deadzone", "Reset to Default"]
	
func _ready() -> void:
	# initialize displays
	set_outer_threshold(Game.joystick_outer_threshold)
	set_axis_deadzone(Game.joystick_axis_deadzone)

func _return_pressed() -> void:
	if slider_controls_enabled:
		# When return (or cancel, the B button) is pressed, revert to prior value.
		match current_menu_index:
			OUTER_THRESHOLD:
				change_slider_state(OUTER_THRESHOLD, false)
				set_outer_threshold(outer_threshold_prior_value)
			AXIS_DEADZONE:
				change_slider_state(AXIS_DEADZONE, false)
				set_axis_deadzone(axis_deadzone_prior_value)
#			EASING_CURVE:
#				change_slider_state(EASING_CURVE, false)
#				set_axis_deadzone(easing_curve_prior_value)
	else:
		current_menu_index = 0
		Game.ui.paused.change_state("customize_menu")
		stop()

# Only update the menu when appropriate
func _up_pressed() -> void:
	if not slider_controls_enabled:
		descriptions.get_child(current_menu_index).visible = false
		._up_pressed() # call MenuClass function to update the index
		descriptions.get_child(current_menu_index).visible = true
func _down_pressed() -> void:
	if not slider_controls_enabled:
		descriptions.get_child(current_menu_index).visible = false
		._down_pressed()
		descriptions.get_child(current_menu_index).visible = true

func set_outer_threshold(value:float) -> void:
	Game.joystick_outer_threshold = value
	outer_threshold_value_label.text = str(value).pad_decimals(3)
	outer_threshold_color_rect.rect_size.x = (1.0 - (value - outer_threshold_minimum) / (1.0 - outer_threshold_minimum)) * slider_width
	outer_threshold_color_rect.rect_position.x = 500 - (outer_threshold_color_rect.rect_size.x)
	raw_left_shader_material.set_shader_param("outer_threshold", value)
	raw_right_shader_material.set_shader_param("outer_threshold", value)
	
func set_axis_deadzone(value:float) -> void:
	Game.joystick_axis_deadzone = value
	axis_deadzone_value_label.text = str(value).pad_decimals(3)
	axis_deadzone_color_rect.rect_size.x = (value / axis_deadzone_maximum) * slider_width
	raw_left_shader_material.set_shader_param("axis_deadzone", value)
	raw_right_shader_material.set_shader_param("axis_deadzone", value)

#func set_easing_curve(value:float) -> void:
#	Game.joystick_easing_curve = value
#	easing_curve_value_label.text = str(value).pad_decimals(3)
#	easing_curve_color_rect.rect_size.x = (value / easing_curve_maximum) * slider_width

func change_slider_state(index:int, state:bool) -> void:
	slider_controls_enabled = state
	match index:
		OUTER_THRESHOLD:
			if state == true:
				outer_threshold_color_rect_bg.color = Color("808040")
				outer_threshold_color_rect.color = Color("ffff80")
				outer_threshold_value_label.self_modulate = Color("ffff80");
			else:
				outer_threshold_color_rect_bg.color = greyed_out
				outer_threshold_color_rect.color = Color("808080")
				outer_threshold_value_label.self_modulate = unselected;
		AXIS_DEADZONE:
			if state == true:
				axis_deadzone_color_rect_bg.color = Color("808040")
				axis_deadzone_color_rect.color = Color("ffff80")
				axis_deadzone_value_label.self_modulate = Color("ffff80");
			else:
				axis_deadzone_color_rect_bg.color = greyed_out
				axis_deadzone_color_rect.color = Color("808080")
				axis_deadzone_value_label.self_modulate = unselected;
#		EASING_CURVE:
#			if state == true:
#				easing_curve_color_rect_bg.color = Color("808040")
#				easing_curve_color_rect.color = Color("ffff80")
#				easing_curve_value_label.self_modulate = Color("ffff80");
#			else:
#				easing_curve_color_rect_bg.color = greyed_out
#				easing_curve_color_rect.color = Color("808080")
#				easing_curve_value_label.self_modulate = unselected;

func _menu_item_selected(index:int) -> void:
	match index:
		OUTER_THRESHOLD:
			if slider_controls_enabled:
				change_slider_state(OUTER_THRESHOLD, false) # disable
			else:
				outer_threshold_prior_value = Game.joystick_outer_threshold
				change_slider_state(OUTER_THRESHOLD, true) # enable
		AXIS_DEADZONE:
			if slider_controls_enabled:
				change_slider_state(AXIS_DEADZONE, false)
			else:
				axis_deadzone_prior_value = Game.joystick_axis_deadzone
				change_slider_state(AXIS_DEADZONE, true)
#		EASING_CURVE:
#			if slider_controls_enabled:
#				change_slider_state(EASING_CURVE, false)
#			else:
#				easing_curve_prior_value = Game.joystick_easing_curve
#				change_slider_state(EASING_CURVE, true)
		RESET_TO_DEFAULT:
			set_outer_threshold(outer_threshold_default)
			set_axis_deadzone(axis_deadzone_default)

func _process(_t:float) -> void:
	if slider_controls_enabled:
		var slide_amount:float = 0.0
		
		if Input.is_action_pressed("d-left"):
			slide_amount -= 0.001
		elif Input.is_action_pressed("ui_left"):
			slide_amount -= 0.01
		
		if Input.is_action_pressed("d-right"):
			slide_amount += 0.001
		elif Input.is_action_pressed("ui_right"):
			slide_amount += 0.01
			
		if slide_amount != 0.0:
			match current_menu_index:
				OUTER_THRESHOLD:
					set_outer_threshold(clamp(Game.joystick_outer_threshold + slide_amount, outer_threshold_minimum, 1.0))
				AXIS_DEADZONE:
					set_axis_deadzone(clamp(Game.joystick_axis_deadzone + slide_amount, 0.0, axis_deadzone_maximum))
#				EASING_CURVE:
#					set_easing_curve(clamp(Game.joystick_easing_curve + slide_amount, easing_curve_minimum, easing_curve_maximum))


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
	raw_left_shader_material.set_shader_param("stick_pos", pos)
	length = pos.length() # Find length
	visual_pos = pos * 127 # Sprite position
	raw_left_stick_pos.position = visual_pos # Set sprite pos
	
	# set colors
	if pos.x == 0.0:
		x_color = greyed_out
		raw_left_stick_x.default_color.a = 0.0
	else:
		x_color = "ff8080"
		raw_left_stick_x.default_color.a = 1.0
	
	if pos.y == 0.0:
		y_color = greyed_out
		raw_left_stick_y.default_color.a = 0.0
	else:
		y_color = "80ff80"
		raw_left_stick_y.default_color.a = 1.0
	
	if length == 0.0:
		length_color = greyed_out
		raw_left_stick_length.default_color.a = 0.0
	else:
		length_color = "8080ff"
		raw_left_stick_length.default_color.a = 1.0
	
	# set line properties
	raw_left_stick_x.points = PoolVector2Array([Vector2(visual_pos.x,-126), Vector2(visual_pos.x, 126)]) # set x axis line points
	raw_left_stick_y.points = PoolVector2Array([Vector2(-126,visual_pos.y), Vector2(126, visual_pos.y)]) # set y axis line points
	raw_left_stick_length.points = PoolVector2Array([Vector2(0,0), visual_pos]) # set length line points
	
	# create data string
	x_str = sign_as_string(pos.x) + str(abs(pos.x)).pad_decimals(3) # format x position as string
	y_str = sign_as_string(pos.y) + str(abs(pos.y)).pad_decimals(3) # format y position as string
	length_str = str(length).pad_decimals(3) # format length as string
	
	# apply data string
	raw_left_stick_data.bbcode_text = '[center][color=#' + x_color + ']X ' + x_str + '[/color] | [color=#' + y_color +']Y ' + y_str + '[/color] | [color=#' + length_color + ']Length ' + length_str + '[/color][/center]'
	
	# LEFT FINAL
	
	pos = Game.get_stick_input("left")
	length = pos.length() # Find length
	visual_pos = pos * 127 # Sprite position
	final_left_stick_pos.position = visual_pos # Set sprite pos
	
	# set colors
	if pos.x == 0.0:
		x_color = greyed_out
		final_left_stick_x.default_color.a = 0.0
	else:
		x_color = "ff8080"
		final_left_stick_x.default_color.a = 1.0
	
	if pos.y == 0.0:
		y_color = greyed_out
		final_left_stick_y.default_color.a = 0.0
	else:
		y_color = "80ff80"
		final_left_stick_y.default_color.a = 1.0
	
	if length == 0.0:
		length_color = greyed_out
		final_left_stick_length.default_color.a = 0.0
	else:
		length_color = "8080ff"
		final_left_stick_length.default_color.a = 1.0
	
	# set line properties
	final_left_stick_x.points = PoolVector2Array([Vector2(visual_pos.x,-126), Vector2(visual_pos.x, 126)]) # set x axis line points
	final_left_stick_y.points = PoolVector2Array([Vector2(-126,visual_pos.y), Vector2(126, visual_pos.y)]) # set y axis line points
	final_left_stick_length.points = PoolVector2Array([Vector2(0,0), visual_pos]) # set length line points
	
	# create data string
	x_str = sign_as_string(pos.x) + str(abs(pos.x)).pad_decimals(3) # format x position as string
	y_str = sign_as_string(pos.y) + str(abs(pos.y)).pad_decimals(3) # format y position as string
	length_str = str(length).pad_decimals(3) # format length as string
	
	var description:String = get_data_desc(pos, length)
	
	# apply data string
	final_left_stick_data.bbcode_text = '[center][color=#' + x_color + ']X ' + x_str + '[/color] | [color=#' + y_color +']Y ' + y_str + '[/color] | [color=#' + length_color + ']Length ' + length_str + '[/color][/center]'
	final_left_stick_datadesc.bbcode_text = '[center]' + description + '[/center]'
	
	#####   ##   #####  ##  ##  ######
	##  ##  ##  ##      ##  ##    ##
	#####   ##  ## ###  ######    ##
	##  ##  ##  ##  ##  ##  ##    ##
	##  ##  ##   ####   ##  ##    ##
	
	pos = Vector2(Input.get_joy_axis(0, 2), Input.get_joy_axis(0, 3)) # Get data from control stick
	raw_right_shader_material.set_shader_param("stick_pos", pos)
	length = pos.length() # Find length
	visual_pos = pos * 127 # Sprite position
	raw_right_stick_pos.position = visual_pos # Set sprite pos
	
	# set colors
	if pos.x == 0.0:
		x_color = greyed_out
		raw_right_stick_x.default_color.a = 0.0
	else:
		x_color = "ff8080"
		raw_right_stick_x.default_color.a = 1.0
	
	if pos.y == 0.0:
		y_color = greyed_out
		raw_right_stick_y.default_color.a = 0.0
	else:
		y_color = "80ff80"
		raw_right_stick_y.default_color.a = 1.0
	
	if length == 0.0:
		length_color = greyed_out
		raw_right_stick_length.default_color.a = 0.0
	else:
		length_color = "8080ff"
		raw_right_stick_length.default_color.a = 1.0
	
	# set line properties
	raw_right_stick_x.points = PoolVector2Array([Vector2(visual_pos.x,-126), Vector2(visual_pos.x, 126)]) # set x axis line points
	raw_right_stick_y.points = PoolVector2Array([Vector2(-126,visual_pos.y), Vector2(126, visual_pos.y)]) # set y axis line points
	raw_right_stick_length.points = PoolVector2Array([Vector2(0,0), visual_pos]) # set length line points
	
	# create data string
	x_str = sign_as_string(pos.x) + str(abs(pos.x)).pad_decimals(3) # format x position as string
	y_str = sign_as_string(pos.y) + str(abs(pos.y)).pad_decimals(3) # format y position as string
	length_str = str(length).pad_decimals(3) # format length as string
	
	# apply data string
	raw_right_stick_data.bbcode_text = '[center][color=#' + x_color + ']X ' + x_str + '[/color] | [color=#' + y_color +']Y ' + y_str + '[/color] | [color=#' + length_color + ']Length ' + length_str + '[/color][/center]'
	
	# RIGHT FINAL
	
	pos = Game.get_stick_input("right")
	length = pos.length() # Find length
	visual_pos = pos * 127 # Sprite position
	final_right_stick_pos.position = visual_pos # Set sprite pos
	
	# set colors
	if pos.x == 0.0:
		x_color = greyed_out
		final_right_stick_x.default_color.a = 0.0
	else:
		x_color = "ff8080"
		final_right_stick_x.default_color.a = 1.0
	
	if pos.y == 0.0:
		y_color = greyed_out
		final_right_stick_y.default_color.a = 0.0
	else:
		y_color = "80ff80"
		final_right_stick_y.default_color.a = 1.0
	
	if length == 0.0:
		length_color = greyed_out
		final_right_stick_length.default_color.a = 0.0
	else:
		length_color = "8080ff"
		final_right_stick_length.default_color.a = 1.0
	
	# set line properties
	final_right_stick_x.points = PoolVector2Array([Vector2(visual_pos.x,-126), Vector2(visual_pos.x, 126)]) # set x axis line points
	final_right_stick_y.points = PoolVector2Array([Vector2(-126,visual_pos.y), Vector2(126, visual_pos.y)]) # set y axis line points
	final_right_stick_length.points = PoolVector2Array([Vector2(0,0), visual_pos]) # set length line points
	
	# create data string
	x_str = sign_as_string(pos.x) + str(abs(pos.x)).pad_decimals(3) # format x position as string
	y_str = sign_as_string(pos.y) + str(abs(pos.y)).pad_decimals(3) # format y position as string
	length_str = str(length).pad_decimals(3) # format length as string
	
	description = get_data_desc(pos, length)
	
	# apply data string
	final_right_stick_data.bbcode_text = '[center][color=#' + x_color + ']X ' + x_str + '[/color] | [color=#' + y_color +']Y ' + y_str + '[/color] | [color=#' + length_color + ']Length ' + length_str + '[/color][/center]'
	final_right_stick_datadesc.bbcode_text = '[center]' + description + '[/center]'
	
func get_data_desc(pos:Vector2, length:float) -> String:
	if pos.x == 0.0 and pos.y == 0.0:
		return "No Input"
	if pos.x == 0.0:
		if pos.y == -1.0:
			return  "Full Input (Up)"
		if pos.y == 1.0:
			return "Full Input (Down)"
		if pos.y < 0.0:
			return "Partial Input (Up)"
		else:
			return "Partial Input (Down)"
	
	if pos.y == 0.0:
		if pos.x == -1.0:
			return "Full Input (Left)"
		if pos.x == 1.0:
			return "Full Input (Right)"
		if pos.x < 0.0:
			return "Partial Input (Left)"
		else:
			return "Partial Input (Right)"
	
	if is_equal_approx(length, 1.0):
		return "Full Input"

	return "Partial Input"

func sign_as_string(number:float):
	match sign(number):
		-1.0 : return "−"
		0.0  : return "±"
		1.0  : return "+"
