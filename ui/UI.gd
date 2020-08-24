extends CanvasLayer

# easy node reference. Game.ui.paused
onready var paused = $Paused 
onready var ingame_ui = $InGame_UI

func _ready() -> void:
	ingame_ui.visible = true
