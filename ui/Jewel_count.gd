extends RichTextLabel

func _ready() -> void:
	Events.connect("jewel_count_changed", self, "update_jewel_count")
	update_jewel_count()

func update_jewel_count() -> void:
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
