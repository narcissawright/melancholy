tool
extends EditorScenePostImport

func post_import(scene):
	for child in scene.get_children():
		if child.name == "Armature":
			var skele = child.get_child(0)
			for mesh in skele.get_children():
				if mesh is MeshInstance:
					mesh.set_surface_material(0, preload("res://actor/playable/melanie/Melanie_Material.tres"))
					mesh.layers = Layers.actor

	var editor_light = DirectionalLight.new()
	scene.add_child(editor_light)
	editor_light.set_owner(scene)
	editor_light.name = "EditorLight"
	editor_light.editor_only = true
	editor_light.transform.origin = Vector3(1, 1, 1)
	editor_light.rotation_degrees = Vector3(-34.6, 10.16, -2.37)
	
	var script = load("res://actor/playable/melanie/melanie_light_passer.gd")
	scene.set_script(script)
	
	return scene
