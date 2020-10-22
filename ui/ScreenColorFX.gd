extends ColorRect

onready var anim = $Anim

func _ready() -> void:
	Events.connect("mysterious_mushroom", self, "mysterious_mushroom")
	
func mysterious_mushroom() -> void:
	material.set_shader_param("fx_color", Color(0.17,0.71,0.25,0.75))
	$Anim.play("fade")
