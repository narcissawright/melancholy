extends Area

const type:String = "pickup"

func interact():
	if Player.current_subweapon == "bomb":
		return false
	Player.current_subweapon = "bomb"
	Player.lockplayer_for_frames(20)
	get_parent().queue_free()
	return true
