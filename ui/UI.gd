extends CanvasLayer

# easy node reference. Game.ui.inventory for example
onready var paused = $Paused 
onready var ingame_ui = $InGame_UI
onready var inventory = $InGame_UI/Inventory

const jewel_color = Color("#00d2ba")
const error_color = Color("#ff1010")

func _ready() -> void:
	ingame_ui.visible = true
