tool
extends EditorScenePostImport

func post_import(scene):
	for child in scene.get_children():
		if child.name == "RiverBridges":
			child.mesh.surface_set_material(1, load("res://levels/riverbridges/grass_shader.tres"))
			child.set_script(load("res://levels/riverbridges/signal_grass_material.gd"))
		if child is MeshInstance:
			if child.name != "Water":
				child.create_trimesh_collision()
	
	return scene
