extends Node2D

onready var clock_sprite = $ClockSprite

func _process(_t:float) -> void:
	var light_vec = Vector3(0, -1, 0.35).normalized()
	light_vec = light_vec.rotated(Vector3.FORWARD, -(Game.time_of_day / 1440.0) * TAU)
	clock_sprite.material.set_shader_param("light_vec", light_vec)
