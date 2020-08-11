tool
extends Spatial

func _process(t:float) -> void:
	var mat = $Armature/Skeleton/Face.get_surface_material(0)
	mat.set_shader_param("light_vec", $EditorLight.translation.normalized())
