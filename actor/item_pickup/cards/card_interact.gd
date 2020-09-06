extends Area

export var item:String = "sun_card"
const type:String = "pickup"

func interact():
	if Game.player.inventory_is_full():
		return false
	Game.player.obtain_item(item)
	Game.player.lockplayer_for_frames(20)
	get_parent().queue_free()
	return true
