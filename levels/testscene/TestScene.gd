extends Spatial

func _ready() -> void:
	Events.connect('checkpoint', self, 'checkpoint_reached')

func checkpoint_reached(where:Vector3) -> void:
	Game.player.checkpoint.position = where
	Game.player.checkpoint.jewels = Game.player.jewels
	Game.player.checkpoint.subweapon = Game.player.current_subweapon
	Game.player.checkpoint.y_rotation = 0.0
	
	# Consider passing a "checkpoint id" into here instead of position/rotation.
	# Might be easier, although the checkpoints would have to be organized to have ids.
