extends Area

const type:String = "pickup"

func interact():
	Game.player.current_subweapon = "bomb"
	Game.player.lockplayer_for_frames(20)
	get_parent().queue_free()
