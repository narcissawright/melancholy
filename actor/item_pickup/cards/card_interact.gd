extends Area

export var item:String = "sun_card"
const type:String = "pickup"

func interact():
	if Player.inventory_is_full():
		return false
	Player.obtain_item(item)
	Player.lockplayer_for_frames(20)
	get_parent().queue_free()
	return true
