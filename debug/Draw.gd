extends ImmediateGeometry

func _ready() -> void:
	process_priority = -50
	
func _physics_process(_t:float) -> void:
	Game.debug.draw.clear()
