extends Area

var amount = 10 # of jewels this is worth

func interact():
	if can_interact():
		Game.player.jewels = min(Game.player.jewels + amount, Game.player.max_jewels)
		Game.player.lockplayer_for_frames(20)
		get_parent().queue_free()

func can_interact() -> bool:
	if Game.player.jewels < Game.player.max_jewels:
		return true
	return false
