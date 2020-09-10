extends MeshInstance

func _ready() -> void:
	Game.player.set_geometry_aabb(get_aabb())
