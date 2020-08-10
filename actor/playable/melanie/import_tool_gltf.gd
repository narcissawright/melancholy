tool
extends EditorScenePostImport

func post_import(scene):
	for child in scene.get_children():
		if child.name == "Armature":
			var skele = child.get_child(0)
			for mesh in skele.get_children():
				if mesh is MeshInstance:
					mesh.set_surface_material(0, preload("res://actor/playable/melanie/Melanie_Material.tres"))

	var editor_light = DirectionalLight.new()
	scene.add_child(editor_light)
	editor_light.set_owner(scene)
	editor_light.name = "EditorLight"
	editor_light.editor_only = true
	editor_light.transform = Basis(Vector3(-0.24, 0.71, 0.65), Vector3(0.396, -0.54, 0.73), Vector3(0.886, 0.43, -0.15))
	print(scene)
	return scene
