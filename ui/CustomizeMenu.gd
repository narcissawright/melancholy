extends Node2D

func _ready() -> void:
	stop()
	
func stop() -> void:
	visible = false
	set_process(false)

func start() -> void:
	visible = true
	set_process(true)
	
func _process(t:float) -> void:
	pass
