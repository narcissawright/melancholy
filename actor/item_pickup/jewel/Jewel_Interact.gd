extends Area

export var amount:int = 10
const type:String = "pickup"

func interact() -> bool: # Returns true if successful
	if Player.jewels == Player.max_jewels:
		return false
	Player.jewels = int(min(Player.jewels + amount, Player.max_jewels))
	Player.lockplayer_for_frames(20)
	get_parent().queue_free()
	return true
