extends Node2D

func _ready() -> void:
	Events.connect("current_subweapon_changed", self, "update_subweapon_icon")

func update_subweapon_icon() -> void:
	for sprite in $BG.get_children():
		sprite.visible = (sprite.name == Game.player.current_subweapon)
