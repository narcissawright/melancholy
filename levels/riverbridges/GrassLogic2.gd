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
	var cubic_meters:float = 0
	for i in range(aabb_array.size()):
		mat.set_shader_param("aabb" + str(i+1) + "pos",  aabb_array[i].position)
		mat.set_shader_param("aabb" + str(i+1) + "size", aabb_array[i].size)
		cubic_meters += aabb_array[i].size.x * aabb_array[i].size.y * aabb_array[i].size.z
		
	var height := int(ceil(((cubic_meters * 64.0) / 8192.0) / 3.0))
	var path_collision_img = Image.new()
	path_collision_img.create(8192, height, false, Image.FORMAT_RGBA5551)
	
	print(8192, " ", height)
	
	var tex = ImageTexture.new()
	tex.create_from_image(path_collision_img, 0)
	
#	var height = ceil((aabb.size.x+1) * (aabb.size.y+1) * (aabb.size.z+1) / 1024.0)
#	path_collision_img = Image.new()
#	path_collision_img.create(1024, height, false, Image.FORMAT_L8)
#	path_collision_tex = ImageTexture.new()
#	path_collision_tex.create_from_image(path_collision_img, 0)


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

	# - Find a way to calculate which bounding box contains a 3d position (in the shader)
	# - Try edge cases like the position not existing in any of the bounding boxes (in the shader AND in gdscript)
	# - Write image data
	# - Draw dirt from shader

func toggle_debug_view(state:bool) -> void:
	aabbs.visible = state

func _on_path_collision(position:Vector3, velocity_length:float) -> void:
	# Find the 8 nearest quarter meter blocks to this position
	# 4x4x4
	print ((position * 4).round() / 4.0)
	

	
#	position = position.round() # I dont wanna round this now that im not using integer blocks
#	var offset # = translation - position
#
#	var x_dir = sign(offset.x)
#	var y_dir = sign(offset.y)
#	var z_dir = sign(offset.z)
##
#	var locations = [
#		position, 
#		position + Vector3(0,     0,     z_dir),
#		position + Vector3(0,     y_dir, 0    ),
#		position + Vector3(0,     y_dir, z_dir),
#		position + Vector3(x_dir, 0,     0    ),
#		position + Vector3(x_dir, 0,     z_dir),
#		position + Vector3(x_dir, y_dir, 0    ),
#		position + Vector3(x_dir, y_dir, z_dir)
#	]
#
#	for i in range (locations.size()):
#		var index:int = get_collision_img_index(locations[i], AABB())
#		var distance = (translation - locations[i]).length()
#		var value:int = int((1.0 - distance) * 0x0F)
#		if value > 0:
#			set_collision_img_data(index, value)

func get_collision_img_index(position:Vector3, aabb:AABB) -> int:
	var diff:Vector3 = position - aabb.position
	return int(diff.x + (diff.y * aabb.size.x) + (diff.z * aabb.size.x * aabb.size.y))

func set_collision_img_data(index:int, value:int) -> void:
	pass
#	var img_data = path_collision_img.data.data
#	var old_value = img_data[index]
#	var new_value = min(old_value + value, 0xFF)
#	img_data.set(index, new_value)
#	path_collision_img.data.data = img_data
#	# warning-ignore:integer_division
#	var y = index / 1024
#	var x = index % 1024
#	VisualServer.texture_set_data_partial(path_collision_tex.get_rid(), path_collision_img, x, y, 1, 1, x, y, 0)
