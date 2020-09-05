extends Node2D

onready var current = $Current
onready var jewels = $Jewels
onready var tween = $Tween

func _ready() -> void:
	Events.connect("current_subweapon_changed", self, "update_subweapon_icon")
	Events.connect("error_no_subweapon", self, "error_no_subweapon")
	update_subweapon_icon()

func error_no_subweapon() -> void:
	tween.stop_all()
	tween.interpolate_property(current, "self_modulate", Game.ui.error_color, Color("#808080"), 1.0, Tween.TRANS_CUBIC, Tween.EASE_OUT)
	tween.start()

func update_subweapon_icon() -> void:
	if tween.is_active():
		tween.stop_all()
	
	if Game.player.current_subweapon != '':
		current.self_modulate = Game.ui.jewel_color
	else:
		current.self_modulate = Color("#808080")
	
	for sprite in current.get_children():
		sprite.visible = (sprite.name == Game.player.current_subweapon)
