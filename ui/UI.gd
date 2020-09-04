extends CanvasLayer

# easy node reference. Game.ui.inventory for example
onready var paused = $Paused 
onready var ingame_ui = $InGame_UI
onready var inventory = $InGame_UI/Inventory

func _ready() -> void:
	ingame_ui.visible = true
