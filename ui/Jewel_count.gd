extends RichTextLabel

# this shouldnt update every frame.

func _process(delta: float) -> void:
	
	if Game.player.jewels == 0:
		bbcode_text = "[center][color=#808080]000[/color][/center]"
	else:
		var jewel_string = str(Game.player.jewels)
		var color_jewel_string = "[color=#ffffff]" + str(Game.player.jewels) + "[/color]"
	
		if jewel_string.length() == 1:
			color_jewel_string = "[color=#808080]00[/color]" + color_jewel_string
		elif jewel_string.length() == 2:
			color_jewel_string = "[color=#808080]0[/color]" + color_jewel_string
	
		bbcode_text = "[center]" + color_jewel_string + "[/center]"
