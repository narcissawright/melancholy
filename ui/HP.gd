extends Node2D

var full_length = 881 # pixels, melanie
onready var tween = $HP_Bar_Tween
onready var hp_bar_light = $HP_Bar_Light
onready var hp_bar_dark = $HP_Bar_Dark
onready var light = $HeartScale/Heart/Light
onready var heart = $HeartScale/Heart

func _ready() -> void:
	full_length = hp_bar_light.rect_size.x
	Events.connect("player_damaged", self, "_on_player_damaged")
	Events.connect("player_respawning", self, "_on_player_respawning")

func _process(_t:float) -> void:
	var light_vec = Vector3(0, -1, 0.35).normalized()
	light_vec = light_vec.rotated(Vector3.FORWARD, -(Game.time_of_day / 1440.0) * TAU)
	heart.material.set_shader_param("light_vec", light_vec)

func _on_player_damaged():
	update_healthbar()

func _on_player_respawning():
	update_healthbar()

func update_healthbar():
	tween.stop_all()
	var new_size = (Game.player.hp / Game.player.max_hp) * full_length
	var difference = hp_bar_light.rect_size.x - new_size
	var tween_time = min(1.5, abs(difference) * Game.frame_time * 0.5)
	if difference > 0.0:
		# Decrease Healthbar
		tween.interpolate_property(hp_bar_dark, "rect_size:x", hp_bar_dark.rect_size.x, new_size, tween_time)
		hp_bar_light.rect_size.x = new_size
	else:
		# Increase Healthbar
		tween.interpolate_property(hp_bar_light, "rect_size:x", hp_bar_light.rect_size.x, new_size, tween_time)
		hp_bar_dark.rect_size.x = new_size
	tween.start()
