tool
extends EditorScenePostImport

func post_import(scene):
	for child in scene.get_children():
		if child.name == "Armature":
			var skele = child.get_child(0)
			var mesh = skele.get_child(0) # Assumes one meshinstance for entire character.
			mesh.set_surface_material(0, preload("res://player/melanie/Melanie_Material.tres"))
			mesh.layers = Layers.actor
			mesh.name = "MeshInstance"
			mesh.set_script(preload("res://player/opacity_dither.gd"))
			
			var bone_attachment = BoneAttachment.new()
			skele.add_child(bone_attachment)
			bone_attachment.set_owner(scene)
			bone_attachment.name = "BombPos"
			bone_attachment.bone_name = "bomb"
			
			var bone_attachment2 = BoneAttachment.new()
			skele.add_child(bone_attachment2)
			bone_attachment2.set_owner(scene)
			bone_attachment2.name = "ShieldPos"
			bone_attachment2.bone_name = "shield"
			
		if child.name == "AnimationPlayer":
			child.get_animation("Idle").loop = true
			child.get_animation("Walk").loop = true
			child.get_animation("BackWalk").loop = true
			child.get_animation("RightWalk").loop = true
			child.get_animation("LeftWalk").loop = true
			child.get_animation("Run").loop = true
			child.get_animation("LedgeCling").loop = true

	var editor_light = DirectionalLight.new()
	scene.add_child(editor_light)
	editor_light.set_owner(scene)
	editor_light.name = "EditorLight"
	editor_light.editor_only = true
	editor_light.transform.origin = Vector3(1, 1, 1)
	editor_light.rotation_degrees = Vector3(-34.6, 10.16, -2.37)
	
#	var anim_tree = load("res://player/melanie/AnimationTree.tscn").instance()
#	scene.add_child(anim_tree)
#	anim_tree.set_owner(scene)
#	anim_tree.active = true
	
	return scene
