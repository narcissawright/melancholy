extends Position3D
onready var bomb = $'Bomb'

func _ready() -> void:
	bomb.hide()

func spawn_bomb() -> void:
	bomb.show()
