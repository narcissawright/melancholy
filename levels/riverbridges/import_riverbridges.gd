tool
extends EditorScenePostImport

func post_import(scene):
	for child in scene.get_children():
		if child.name == "RiverBridges":
			var grass_surface_index = 1
			child.mesh.set('surface_' + str(grass_surface_index + 1) + '/name', 'Grass')
			child.mesh.surface_set_material(grass_surface_index, load("res://levels/riverbridges/grass_shader.tres"))
			child.set_script(load("res://levels/riverbridges/signal_grass_material.gd"))
			child.grass_surface_index = grass_surface_index
		if child is MeshInstance:
			if child.name != "Water":
				child.create_trimesh_collision()
	
	return scene
