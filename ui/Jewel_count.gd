extends Node2D 
onready var label = $Jewel_count
onready var icon = $JewelIcon_Front
onready var tween = $Tween

var prior_jewel_string:String

func _ready() -> void:
	Events.connect("jewel_count_changed", self, "jewel_count_changed")
	Events.connect("jewel_cost_too_high", self, "insufficient_jewels")
	update_jewel_text()

func insufficient_jewels() -> void:
	if tween.is_active():
		tween.stop_all()
	else:
		prior_jewel_string = label.bbcode_text
	tween.interpolate_method(self, "set_insufficient_color", 1.0, 0.0, 1.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tween.start()

func set_insufficient_color(red_amount:float) -> void:
	icon.modulate = UI.jewel_color.linear_interpolate(UI.error_color, red_amount)
	var grey:String = Color("#808080").linear_interpolate(UI.error_color, red_amount).to_html()
	var white:String = Color("#ffffff").linear_interpolate(UI.error_color, red_amount).to_html()
	label.bbcode_text = prior_jewel_string.replace("808080", grey).replace("ffffff", white)

func _insufficient_tween_completed(_object: Object, _key: NodePath) -> void:
	icon.modulate = UI.jewel_color
	update_jewel_text()

func jewel_count_changed() -> void:
	if tween.is_active():
		tween.stop_all()
		icon.modulate = UI.jewel_color
	update_jewel_text()
		
func update_jewel_text() -> void:
	if Player.jewels == 0:
		label.bbcode_text = "[center][color=#808080]000[/color][/center]"
	else:
		var jewel_string = str(Player.jewels)
		var color_jewel_string = "[color=#ffffff]" + str(Player.jewels) + "[/color]"
	
		if jewel_string.length() == 1:
			color_jewel_string = "[color=#808080]00[/color]" + color_jewel_string
		elif jewel_string.length() == 2:
			color_jewel_string = "[color=#808080]0[/color]" + color_jewel_string
	
		label.bbcode_text = "[center]" + color_jewel_string + "[/center]"

