extends Area

func _target_acquired(area: Area) -> void:
	Player.TargetSystem.target_acquired(area)
	
func _target_lost(area: Area) -> void:
	Player.TargetSystem.target_lost(area)
