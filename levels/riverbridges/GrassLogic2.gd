extends Node
onready var aabbs = $AABBs

func _ready() -> void:
	# Initialize
	aabbs.visible = false
	Events.connect("debug_view", self, "toggle_debug_view")
	Events.connect("path_collision", self, "_on_path_collision")
	
	# Obtain data from AABBs
	var aabb_array = []
	for child in aabbs.get_children():
		var aabb = AABB(child.position, child.size)
		aabb_array.append(aabb)
	print (aabb_array)

	var mat = $AABB_TEXTURE2.get_surface_material(0)
	var cubic_meters:int = 0
	for i in range(aabb_array.size()):
		mat.set_shader_param("aabb" + str(i+1) + "pos",  aabb_array[i].position)
		mat.set_shader_param("aabb" + str(i+1) + "size", aabb_array[i].size)
		cubic_meters += aabb_array[i].size.x * aabb_array[i].size.y * aabb_array[i].size.z
		
	print(cubic_meters * 64)
	var path_collision_img = Image.new()
	path_collision_img.create(1024, 1024, false, Image.FORMAT_RGBA5551)
	
	var path_collision_img2 = Image.new()
	path_collision_img2.create(512, 512, false, Image.FORMAT_RGBA5551)
	
	var tex_array = TextureArray.new()
	tex_array.set_layer_data(path_collision_img, 0)
	tex_array.set_layer_data(path_collision_img2, 0)
	#path_collision_img.create(8192, height, false, Image.FORMAT_RGBA5551)

#	var height = ceil((aabb.size.x+1) * (aabb.size.y+1) * (aabb.size.z+1) / 1024.0)
#	path_collision_img = Image.new()
#	path_collision_img.create(1024, height, false, Image.FORMAT_L8)
#	path_collision_tex = ImageTexture.new()
#	path_collision_tex.create_from_image(path_collision_img, 0)
#	$TextureRect.texture = path_collision_tex
#	Level.get_node("level1/Geometry").get_surface_material(0).set_shader_param("collision_data", path_collision_tex)



# painful failure to convert AABB data into an image and have it read from the shader

	# Transform data into signed 16bit ints
#	var data = PoolByteArray()
#	for i in range (aabb_array.size()):
#		var values = [
#			aabb_array[i].position.x, 
#			aabb_array[i].position.y, 
#			aabb_array[i].position.z, 
#			aabb_array[i].size.x, 
#			aabb_array[i].size.y, 
#			aabb_array[i].size.z
#		]
#
#		for j in range (values.size()):
#
		
#		for j in range (values.size()):
#			var sixteenbit = int(abs(values[j]))
#			if sign(values[j]) == -1:
#				sixteenbit = ~sixteenbit + 1
#			data.append(sixteenbit >> 8)
#			data.append(sixteenbit & 0b0000000011111111)
#
#	print (data.hex_encode())
#
#	# Create image from data
#	var aabb_data_img = Image.new()                             # 16 bits per channel
#	aabb_data_img.create_from_data(2, aabb_array.size(), false, Image.FORMAT_RGBH, data)
#	var aabb_data_tex = ImageTexture.new()
#	aabb_data_tex.create_from_image(aabb_data_img, 0)
#
#	assert (ResourceSaver.save("res://levels/riverbridges/texture/aabb_data_tex.tres", aabb_data_tex) == OK)
	
	#print (aabb_data_tex.get_data().data.data.hex_encode())
	
	#var error = aabb_data_img.save_png("res://levels/riverbridges/texture/aabb_data_img.png")
	#assert (error == 0)
#
#	$AABB_TEXTURE.get_surface_material(0).albedo_texture = aabb_data_tex
#	$AABB_TEXTURE2.get_surface_material(0).set_shader_param("aabb_data", aabb_data_tex)
	
	
	# I'm assuming I did this correctly.
	# Next step.......
	# - Make sure the shader can get the data from the img successfully
	# - Create the path image
	# - Find a way to calculate which bounding box contains a 3d position (in the shader)
	# - Try edge cases like the position not existing in any of the bounding boxes (in the shader AND in gdscript)
	# - Write image data
	# - Draw dirt from shader

func toggle_debug_view(state:bool) -> void:
	aabbs.visible = state

func _on_path_collision(_position:Vector3, _velocity_length:float) -> void:
	pass
