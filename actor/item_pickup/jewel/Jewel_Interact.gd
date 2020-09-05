extends Area

export var amount:int = 10
const type:String = "pickup"

func interact() -> bool: # Returns true if successful
	if Game.player.jewels == Game.player.max_jewels:
		return false
	Game.player.jewels = min(Game.player.jewels + amount, Game.player.max_jewels)
	Game.player.lockplayer_for_frames(20)
	get_parent().queue_free()
	return true
