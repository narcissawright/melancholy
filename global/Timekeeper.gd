extends Node

onready var tween = $Tween
var timescale:float = 1.0
var time_of_day:float = 540.0
var tween_duration = 5.0

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

func can_use_card() -> bool:
	return not fast_forwarding

var fast_forwarding:bool = false
func use_card(type:String):
	var target_time:float = 0.0
	match type:
		"sun":
			target_time = 360.0
		"moon":
			target_time = 1080.0
	fast_forwarding = true 
	var initial_tod:float = time_of_day
	var target_distance:float = target_time - time_of_day
	if sign(target_distance) == -1:
		target_distance += 1440.0
	tween.interpolate_method(self, "fast_forward", 
		initial_tod, initial_tod + target_distance, tween_duration, 
		Tween.TRANS_CUBIC, Tween.EASE_IN_OUT)
	tween.start()

func fast_forward(time_value:float):
	time_of_day = time_value
	time_of_day = fmod(time_of_day, 1440.0)

func _on_Tween_completed(_object: Object, _key: NodePath) -> void:
	timescale = 1.0
	fast_forwarding = false

func _physics_process(t:float) -> void:
	if not get_tree().paused and not fast_forwarding:
		var time_travel = t * timescale
		time_of_day = fmod(time_of_day + time_travel, 1440.0)
		
#		if fastforward:
#			target_distance -= time_travel
#			if target_distance <= 0:
#				time_of_day = target_time
#				target_time = 0.0 
#				fastforward = false
#				timescale = 1.0
	
	Debug.text.write("Timescale: " + str(timescale))
	Debug.text.write("Time of day: " + time_readable(time_of_day))
			
			
			
			
			
