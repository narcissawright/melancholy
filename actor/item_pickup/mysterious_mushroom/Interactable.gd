extends Area

const type:String = "pickup"

func interact() -> bool: # Returns true if successful
	print ("Mysterious Mushroom")
	Player.lockplayer_for_frames(20)
	get_parent().queue_free()
	return true
