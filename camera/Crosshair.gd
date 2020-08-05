extends ImmediateGeometry

func _ready() -> void:
	var length = 0.15
	begin(Mesh.PRIMITIVE_LINES)
	set_color(Color(0.9,0.2,0.2))
	add_vertex(Vector3.LEFT * length)
	add_vertex(Vector3.RIGHT * length)
	set_color(Color(0.2,0.8,0.2))
	add_vertex(Vector3.UP * length)
	add_vertex(Vector3.DOWN * length)
	set_color(Color(0.2,0.2,1))
	add_vertex(Vector3.FORWARD * length)
	add_vertex(Vector3.BACK * length)
	end()
