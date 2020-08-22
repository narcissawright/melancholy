extends Area

const amount:int = 10 # of jewels this is worth
const type:String = "pickup"

func interact():
	Game.player.jewels = min(Game.player.jewels + amount, Game.player.max_jewels)
	Game.player.lockplayer_for_frames(20)
	get_parent().queue_free()
