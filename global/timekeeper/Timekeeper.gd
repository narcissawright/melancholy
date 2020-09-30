extends Node

onready var tween = $TimeOfDayTween
onready var playtime_tween = $PlaytimeTween
const timescale:float = 1.0
var time_of_day:float = 540.0
var tween_duration:float = 5.0
var playtime:float = 0.0

func _ready() -> void:
	Events.connect("respawn", self, "respawn")
	Events.connect("pause", self, "pause_state_changed")

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
	fast_forwarding = false

func respawn() -> void:
	tween.stop_all()
	fast_forwarding = false

func format_time(time:float) -> String:
	var seconds = fmod(time, 60.0)
	# warning-ignore:integer_division
	var minutes = int(time) / 60
	return str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2).pad_decimals(2)

var playtime_multiplier = 1.0
func pause_state_changed(value:bool) -> void:
	if value == true:
		playtime_tween.interpolate_property(self, "playtime_multiplier", null, 0.001, 1.0)
		playtime_tween.start()
	else:
		playtime_tween.stop_all()
		playtime_multiplier = 1.0

func _physics_process(t:float) -> void:
	playtime += (t * playtime_multiplier)
	UI.speedtimer.text = format_time(playtime)
	
	if not get_tree().paused:
		if not fast_forwarding:
			var time_travel = t * timescale
			time_of_day = fmod(time_of_day + time_travel, 1440.0)
	Debug.text.write("Time of day: " + time_readable(time_of_day))
	
