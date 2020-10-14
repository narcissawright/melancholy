extends Spatial

func _ready() -> void:
	Events.connect('checkpoint', self, 'checkpoint_reached')

func checkpoint_reached(where:Vector3) -> void:
	pass
	Player.checkpoint.position = where
	Player.checkpoint.jewels = Player.jewels
	Player.checkpoint.subweapon = Player.current_subweapon
	Player.checkpoint.y_rotation = 0.0
	
	# Consider passing a "checkpoint id" into here instead of position/rotation.
	# Might be easier, although the checkpoints would have to be organized to have ids.
