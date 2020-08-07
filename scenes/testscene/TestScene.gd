extends Spatial

func _ready() -> void:
	Events.connect('checkpoint', self, 'checkpoint_reached')

func checkpoint_reached(where:Vector3) -> void:
	# I might want to have a Y axis rotation
	# or facing direction for the checkpoint
	# otherwise cam will reset along world z axis
	
	# I was also considering passing a "checkpoint id" into here
	# instead of position and rotation
	# might be easier, although I would have to organize
	# the checkpoints so I know which one is which
	
	# I also need to think of how to track "level state"
	# ie. what ends up getting saved by the checkpoint
	# and what is irrelevant
	
	# You know, without having actual levels with functional goals
	# it sort of feels weird to code this now
	
	# But at the very least I can update the respawn state
	# Checkpoints could probably also let you keep your jewels
	# Even though they would power you down 1 level.
	
	print (where)
