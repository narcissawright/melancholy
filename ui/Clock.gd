extends Node2D

onready var hour_hand = $ClockSprite/Hours
onready var minute_hand = $ClockSprite/Minutes
onready var sunmoon = $SunMoon

func _process(_t:float) -> void:
	hour_hand.rotation = Game.timekeeper.time_of_day / 720.0 * TAU
	minute_hand.rotation = fmod(Game.timekeeper.time_of_day, 60.0) * TAU / 60.0
	
	# maybe this should use a fade with 2 sprites instead of animatedsprite.
	if Game.timekeeper.time_of_day > 360.0 and Game.timekeeper.time_of_day < 1080.0:
		sunmoon.frame = 0
	else:
		sunmoon.frame = 1
