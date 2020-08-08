extends Control

onready var text = $"Text"
onready var draw = $"Draw"

func _process(delta:float) -> void:
	if Input.is_action_just_pressed("debug"):
		visible = not visible
