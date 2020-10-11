extends Control

onready var text = $"Text"
onready var draw = $"Draw"
var lines_mat = preload("DebugLinesMaterial.tres")
var fill_mat = preload("DebugFillMaterial.tres")

func _process(_delta:float) -> void:
	if Input.is_action_just_pressed("debug"):
		visible = not visible
		Events.emit_signal("debug_view", visible)
