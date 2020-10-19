extends MeshInstance

func _ready() -> void:
	Events.emit_signal("grass_material", self.mesh.surface_get_material(1))
