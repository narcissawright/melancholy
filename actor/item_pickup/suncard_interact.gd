extends Area

const type:String = "pickup"

func interact():
	print("Get sun card")
	Game.player.lockplayer_for_frames(20)
	get_parent().queue_free()
