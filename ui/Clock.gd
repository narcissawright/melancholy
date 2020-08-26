extends Node2D

onready var hour_hand = $ClockSprite/Hours
onready var minute_hand = $ClockSprite/Minutes

func _process(_t:float) -> void:
	hour_hand.rotation = Game.timekeeper.time_of_day / 720.0 * TAU
	minute_hand.rotation = fmod(Game.timekeeper.time_of_day, 60.0) * TAU / 60.0
