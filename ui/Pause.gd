extends Node2D


func _ready() -> void:
	visible = false
	Events.connect("pause", self, "pause_state_changed")
	
func pause_state_changed(state:bool) -> void:
	visible = state
