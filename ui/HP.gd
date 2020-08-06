extends Node2D

var full_length = 881 # pixels, melanie
onready var hp_bar = $HP_Bar
onready var light = $HeartScale/Heart/Light
onready var heart = $HeartScale/Heart

func _ready() -> void:
	Events.connect("player_damaged", self, "_on_player_damaged")

func _process(_t:float) -> void:
	var light_vec = Vector3(0, -1, 0.35).normalized()
	light_vec = light_vec.rotated(Vector3.FORWARD, -(Game.time_of_day / 1440.0) * TAU)
	heart.material.set_shader_param("light_vec", light_vec)

func _on_player_damaged():
	hp_bar.rect_size.x = (Game.player.hp / Game.player.max_hp) * full_length
