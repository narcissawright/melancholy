extends Area

var amount = 10 # of jewels this is worth

func interact():
	if Game.player.jewels < Game.player.max_jewels:
		Game.player.jewels = min(Game.player.jewels + amount, Game.player.max_jewels)
		Events.emit_signal("jewel_count_changed")
		Game.player.lockplayer_for_frames(20)
		get_parent().queue_free()
