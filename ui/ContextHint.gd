extends Node2D

onready var anim = $AnimationPlayer

func _ready() -> void:
	anim.play("FadeOut")
	anim.seek(0.1, true)

func fadein() -> void:
	anim.play("FadeIn")
	
func fadeout() -> void:
	anim.play("FadeOut")
