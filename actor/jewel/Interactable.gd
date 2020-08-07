extends Area

func interact():
	Game.player.jewels += 10
	Game.player.lockplayer_for_frames(20)
	get_parent().queue_free()
