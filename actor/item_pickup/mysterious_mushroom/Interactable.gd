extends Area

"""
Needs SFX and Graphical effect
"""

const type:String = "pickup"

func interact() -> bool: # Returns true if successful
	#print ("Mysterious Mushroom")
	Events.emit_signal("grass_data_reset")
	Player.lockplayer_for_frames(20)
	get_parent().queue_free()
	return true
