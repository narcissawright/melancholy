extends MeshInstance

func _ready() -> void:
	var aabb:AABB = get_aabb()
	Player.set_geometry_aabb(aabb)
	var grass = get_surface_material(0)
	#grass.set_shader_param("collision_data", Game.player.img_texture)
	grass.set_shader_param("aabb_position", aabb.position)
	grass.set_shader_param("aabb_size", aabb.size)
