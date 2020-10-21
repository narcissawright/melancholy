tool
extends EditorScenePostImport

func post_import(scene):
	for child in scene.get_children():
		if child.name == "RiverBridges":
			child.mesh.set("surface_2/name", "Grass")
			child.mesh.surface_set_material(1, load("res://levels/riverbridges/grass_shader.tres"))
			child.set_script(load("res://levels/riverbridges/signal_grass_material.gd"))
			child.create_trimesh_collision()
		if child.name == "BowPlats":
			child.create_trimesh_collision()
	
	return scene
