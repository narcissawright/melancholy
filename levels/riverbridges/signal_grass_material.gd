extends MeshInstance

export(int) var grass_surface_index

func _ready() -> void:
	Events.emit_signal("grass_surface", mesh, grass_surface_index)
#	Events.emit_signal("grass_material", self.mesh.surface_get_material(1))
