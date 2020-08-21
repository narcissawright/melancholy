extends Node2D

const size = 256

onready var XY = $XY
onready var calibration_circle = $CalibrationCircle
onready var stickpos_l = $CalibrationCircle/StickPos_Left
onready var stickpos_r = $CalibrationCircle/StickPos_Right

func _process(_t:float) -> void:
	var pos = Vector2(Input.get_joy_axis(0, 0), Input.get_joy_axis(0, 1))
	var length = pos.length()
#	if pos.length() > 1.0:
#		pos = pos.normalized()
	
	stickpos_l.position = pos * size
	#stickpos_r.position = Game.get_stick_input("right") * size
	calibration_circle.material.set_shader_param("outer_deadzone", Game.joystick_outer_deadzone)
	calibration_circle.material.set_shader_param("inner_deadzone", Game.joystick_inner_deadzone)

	var format_string = '[center][color=#ff2020]X: %s[/color]\n[color=#20B020]Y: %s[/color]\n[color=#3030ff]Length: %s[/color]\n[/center]'
	var arr = [str(pos.x), str(pos.y), str(length)]
	XY.bbcode_text = format_string % arr
