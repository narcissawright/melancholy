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
		
	# Sort AABBs by volume to do less containment checks on average
	aabb_array.sort_custom(self, "sort_by_volume")
	print(aabb_array)
	
	# Calculate offsets
	var cubic_meters:float = 0
	var aabb_data_img = Image.new()
	var data := PoolByteArray()
	for i in range (aabb_array.size()):
		aabb_offsets.append(cubic_meters * 64)
		
		var relevant_data:Array = []
		relevant_data.append(aabb_array[i].position.x) #RG 1
		relevant_data.append(aabb_array[i].position.y) #RG 2
		relevant_data.append(aabb_array[i].position.z) #RG 3
		relevant_data.append(aabb_array[i].size.x)     #RG 4
		relevant_data.append(aabb_array[i].size.y)     #RG 5
		relevant_data.append(aabb_array[i].size.z)     #RG 6
		
		# add the AABB position and size data to the img
		for j in range (relevant_data.size()):
			# Add 32768 so I don't have to store negative 16bit numbers (headache)
			var stored_value := int(relevant_data[j]) + 32768
			data.append(stored_value / 256) # R x
			data.append(stored_value % 256) # G x
			
		var offset = int(cubic_meters * 64)
		data.append((offset / 16777216) % 256) # R 7
		data.append((offset / 65536) % 256)    # G 7
		data.append((offset / 256) % 256)      # R 8
		data.append( offset % 256)             # G 8
		cubic_meters += aabb_array[i].get_area()
		
	print(data.hex_encode())
	aabb_data_img.create_from_data(8, aabb_array.size(), false, Image.FORMAT_RG8, data)
	# Image.FORMAT_RG8 does not do an sRGB conversion, so the data that goes in can be 
	# safely converted back into bytes in the shader (with a little math).

	var aabb_data_tex = ImageTexture.new()
	aabb_data_tex.create_from_image(aabb_data_img, 0)
	$AABB_TEXTURE2.get_surface_material(0).albedo_texture = aabb_data_tex
	grass_material.set_shader_param("aabb_data", aabb_data_tex)

	# Calculate image size, create image
	var height := int(ceil(((cubic_meters * 64.0) / 8192.0) / 3.0))
	path_collision_img = Image.new()
	path_collision_img.create(8192, height, false, Image.FORMAT_RGBA5551)
#	print(8192, " ", height)
#	print(aabb_offsets)
#	print(cubic_meters * 64)
	
	# Create texture.
	path_collision_tex = ImageTexture.new()
	path_collision_tex.create_from_image(path_collision_img, 0)
	
	# Set shader params
	var display_material = $AABB_TEXTURE.get_surface_material(0)
	display_material.albedo_texture = path_collision_tex
	grass_material.set_shader_param('collision_data', path_collision_tex)

static func sort_by_volume(a:AABB, b:AABB) -> bool:
	if a.get_area() > b.get_area():
		return true
	return false

func toggle_debug_view(state:bool) -> void:
	aabb_container.visible = state

func determine_relevant_aabb(point:Vector3) -> int:
	for i in range (aabb_array.size()):
		if aabb_array[i].has_point(point):
			return i
	return -1

func _on_path_collision(position:Vector3, _velocity_length:float) -> void:
	# Find the 8 nearest quarter meter blocks to this position
	
	var quarter_pos:Vector3 = (position * 4).round() / 4.0 # nearest 

	var x_sign := int(sign(position.x - quarter_pos.x));
	var y_sign := int(sign(position.y - quarter_pos.y));
	var z_sign := int(sign(position.z - quarter_pos.z));
	if x_sign == 0: x_sign = 1 # Sometimes, the quarter pos (rounded)
	if y_sign == 0: y_sign = 1 # and the position share the same value on an axis.
	if z_sign == 0: z_sign = 1 # This ensures I always get 8 different blocks.
	# Another (probably better) solution would be to not append to array if sign is 0.
	
	var positions:Array = [quarter_pos]
	positions.append(quarter_pos + Vector3(     0,      0, z_sign) * 0.25)
	positions.append(quarter_pos + Vector3(     0, y_sign,      0) * 0.25)
	positions.append(quarter_pos + Vector3(     0, y_sign, z_sign) * 0.25)
	positions.append(quarter_pos + Vector3(x_sign,      0,      0) * 0.25)
	positions.append(quarter_pos + Vector3(x_sign,      0, z_sign) * 0.25)
	positions.append(quarter_pos + Vector3(x_sign, y_sign,      0) * 0.25)
	positions.append(quarter_pos + Vector3(x_sign, y_sign, z_sign) * 0.25)
	
	#print (positions)
	for i in range (positions.size()):
		var aabb_index = determine_relevant_aabb(positions[i])
		if aabb_index == -1:
			continue # No relevant AABB found, stop here.
		
		var index:int = get_collision_img_index(positions[i], aabb_index)
		var distance = (position - positions[i]).length()
		var value:int = int((0.25 - distance) * 0xFF)
		if value > 0:
			#print ("Setting value ", value, " at index ", index)
			set_collision_img_data(index, value)

func get_collision_img_index(position:Vector3, aabb_index:int) -> int:
	# index is data index, so 3 of those per pixel
	var aabb:AABB = aabb_array[aabb_index]
	var diff:Vector3 = position - aabb.position
	
	var max_x = aabb.size.x / 0.25
	var max_y = aabb.size.y / 0.25
	#var max_z = aabb.size.z / 0.25
	
	var x_component = diff.x / 0.25
	var y_component = diff.y / 0.25
	var z_component = diff.z / 0.25
	
	var index = x_component + (y_component * max_x) + (z_component * max_x * max_y)
	index += aabb_offsets[aabb_index]

#	print("Pos: ", position)
#	print("AABB: ", aabb)
#	print("Diff: ", diff)
#	print(x_component, ' ', y_component, ' ', z_component)
#	print(max_x, ' ', max_y, ' ', max_z)
#	print("Index: ", index)
	
	return index

func set_collision_img_data(index:int, value:int) -> void:
	# In this case, index is the index of the block data
	# Block data is stored 3 per pixel
	# Each pixel is 2 bytes
	# The green channel is spread between the two bytes
	# I need to grab the relevant pixel (two bytes).
	
	var img_data = path_collision_img.data.data
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
	# considering that I am writing to individual channels and i might be writing twice to the same pixel
	# i should store the pixel index and a list of writes to do after all data has been set.
	


	
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

