extends Node
onready var aabb_container = $AABBs

# Materials
var grass_material

# AABB Data
var aabb_array:Array
var aabb_offsets:Array # how far do you jump to reach the data (in path_collision_img) for the AABB

# Image Data
var path_collision_img:Image
var path_collision_tex:ImageTexture

func sort_by_volume(a:AABB, b:AABB) -> bool:
	if a.get_area() > b.get_area():
		return true
	return false

func _ready() -> void:
	# Initialize
	aabb_container.visible = false
	Events.connect("debug_view", self, "toggle_debug_view")
	Events.connect("path_collision", self, "_on_path_collision")
	
	# Get grass material
	var geometry = $"../Geometry"
	for i in range (geometry.mesh.get_surface_count()):
		if (geometry.mesh.get("surface_" + str(i+1) + "/name")) == "Grass":
			grass_material = geometry.mesh.surface_get_material(i)
	
	# Obtain data from AABBs
	for child in aabb_container.get_children():
		aabb_array.append(AABB(child.position, child.size))

	print (aabb_array)
	aabb_array.sort_custom(self, "sort_by_volume")
	print (aabb_array)

	var cubic_meters:float = 0
	for i in range(aabb_array.size()):
		aabb_offsets.append(cubic_meters * 64)
		grass_material.set_shader_param("aabb" + str(i+1) + "pos",  aabb_array[i].position)
		grass_material.set_shader_param("aabb" + str(i+1) + "size", aabb_array[i].size)
		cubic_meters += aabb_array[i].size.x * aabb_array[i].size.y * aabb_array[i].size.z
		
	var height := int(ceil(((cubic_meters * 64.0) / 8192.0) / 3.0))
	path_collision_img = Image.new()
	path_collision_img.create(8192, height, false, Image.FORMAT_RGBA5551)
	
	print(8192, " ", height)
	print(aabb_offsets)
	print(cubic_meters * 64)
	
	path_collision_tex = ImageTexture.new()
	path_collision_tex.create_from_image(path_collision_img, 0)
	
	var display_material = $AABB_TEXTURE.get_surface_material(0)
	display_material.albedo_texture = path_collision_tex
	grass_material.set_shader_param('collision_data', path_collision_tex)
	
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
	aabb_container.visible = state

func determine_relevant_aabb(point:Vector3) -> int:
	for i in range (aabb_array.size()):
		if aabb_array[i].has_point(point):
			return i
	return -1

func _on_path_collision(position:Vector3, _velocity_length:float) -> void:
	# Find the 8 nearest quarter meter blocks to this position
	
	var quarter_pos = (position * 4).round() / 4.0 # nearest 
	
	var aabb_index = determine_relevant_aabb(quarter_pos)
	if aabb_index == -1:
		return # No relevant AABB found, stop here.
	
	var index:int = get_collision_img_index(quarter_pos, aabb_index)
	var distance = (position - quarter_pos).length()
	var value:int = int((0.25 - distance) * 0x0F)
	if value > 0:
		#print ("Setting value ", value, " at index ", index)
		set_collision_img_data(index, value)

func get_collision_img_index(position:Vector3, aabb_index:int) -> int:
	var aabb = aabb_array[aabb_index]
	var diff:Vector3 = position - aabb.position
	return int(diff.x + (diff.y * aabb.size.x) + (diff.z * aabb.size.x * aabb.size.y)) + aabb_offsets[aabb_index]

func set_collision_img_data(index:int, value:int) -> void:
	# In this case, index is the index of the block data
	# Block data is stored 3 per pixel
	# Each pixel is 2 bytes
	# The green channel is spread between the two bytes
	# I need to grab the relevant pixel (two bytes).
	
	var img_data = path_collision_img.data.data
	# warning-ignore:integer_division
	var pixel_index = index / 3
	var pixel_data_left  = img_data[pixel_index * 2]
	var pixel_data_right = img_data[pixel_index * 2 + 1]
	var full_pixel_data = pixel_data_left * 256 + pixel_data_right
	var channel = index % 3
	match channel:
		0: # RED
			var old_value = (full_pixel_data & 0b1111100000000000) >> 11
			var new_value = min(old_value + value, 31)
			full_pixel_data &= 0b0000011111111110
			full_pixel_data |= new_value << 11 
		1: # GREEN
			var old_value = (full_pixel_data & 0b0000011111000000) >> 6
			var new_value = min(old_value + value, 31)
			full_pixel_data &= 0b1111100000111110
			full_pixel_data |= new_value << 6
		2: # BLUE
			var old_value = (full_pixel_data & 0b0000000000111110) >> 1
			var new_value = min(old_value + value, 31)
			full_pixel_data &= 0b1111111111000000
			full_pixel_data |= new_value << 1
	pixel_data_left = full_pixel_data >> 8
	pixel_data_right = full_pixel_data % 256
	img_data.set(pixel_index * 2,     pixel_data_left)
	img_data.set(pixel_index * 2 + 1, pixel_data_right)
	path_collision_img.data.data = img_data
	var y = pixel_index / 8192
	var x = pixel_index % 8192
	VisualServer.texture_set_data_partial(path_collision_tex.get_rid(), path_collision_img, x, y, 1, 1, x, y, 0)



	
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

