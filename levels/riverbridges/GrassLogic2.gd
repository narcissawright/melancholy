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

const block_size:float = 0.5
var blocks_per_cubic_meter:float

func _ready() -> void:
	blocks_per_cubic_meter = pow((1.0 / block_size), 3)
	
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
		aabb_offsets.append(cubic_meters * blocks_per_cubic_meter)
		
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
			
		var offset = int(cubic_meters * pow((1.0 / block_size), 3))
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
	var height := int(ceil(((cubic_meters * blocks_per_cubic_meter) / 8192.0) / 3.0))
	path_collision_img = Image.new()
	path_collision_img.create(8192, height, false, Image.FORMAT_RGBA5551)
	
	# Create texture.
	path_collision_tex = ImageTexture.new()
	path_collision_tex.create_from_image(path_collision_img, 0)
	
	# Set shader params
	var display_material = $AABB_TEXTURE.get_surface_material(0)
	display_material.albedo_texture = path_collision_tex
	grass_material.set_shader_param('collision_data', path_collision_tex)
	grass_material.set_shader_param('block_size', block_size)

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
	# Find the 8 nearest blocks to this position
	
	var rounded_pos:Vector3 = (position / block_size).round() * block_size # nearest 
	#rounded_pos += (Vector3(block_size, block_size, block_size) * 0.5)
	var x_sign := int(sign(position.x - rounded_pos.x));
	var y_sign := int(sign(position.y - rounded_pos.y));
	var z_sign := int(sign(position.z - rounded_pos.z));

	var try_positions:Array = [
		rounded_pos + Vector3(     0,      0, z_sign) * block_size,
		rounded_pos + Vector3(     0, y_sign,      0) * block_size,
		rounded_pos + Vector3(     0, y_sign, z_sign) * block_size,
		rounded_pos + Vector3(x_sign,      0,      0) * block_size,
		rounded_pos + Vector3(x_sign,      0, z_sign) * block_size,
		rounded_pos + Vector3(x_sign, y_sign,      0) * block_size,
		rounded_pos + Vector3(x_sign, y_sign, z_sign) * block_size
	]
	
	# I check if we already have these positions, which happens when
	# the x_sign, y_sign, or z_sign are zero. This will happepn on
	# surfaces that have integer coordinates.
	var positions:Array = [rounded_pos]
	for i in range (try_positions.size()):
		if not positions.has(try_positions[i]):
			positions.append(try_positions[i])
	
	$DebugView.draw_positions(positions, block_size)
	
	var pixel_positions := []
	
	for i in range (positions.size()):
		var aabb_index = determine_relevant_aabb(positions[i])
		if aabb_index == -1:
			continue # No relevant AABB found, stop here.
		
		var index:int = get_collision_img_index(positions[i], aabb_index)
		var distance = (position - positions[i]).length()
		var value:int = int((block_size - distance) * 0xFF)
		if value > 0:
			#print ("Setting value ", value, " at index ", index)
			var pixel = set_collision_img_data(index, value)
			if not pixel_positions.has(pixel):
				pixel_positions.append(pixel)
	
	for i in range (pixel_positions.size()):
		# I would like to support doing writes of 2 pixels at once if they are adjacent
		# but I want to know if that would increase performance
		VisualServer.texture_set_data_partial(path_collision_tex.get_rid(), path_collision_img, pixel_positions[i].x, pixel_positions[i].y, 1, 1, pixel_positions[i].x, pixel_positions[i].y, 0)

func get_collision_img_index(position:Vector3, aabb_index:int) -> int:
	var aabb:AABB = aabb_array[aabb_index]
	var diff:Vector3 = position - aabb.position
	
	var max_x = aabb.size.x / block_size
	var max_y = aabb.size.y / block_size
	
	var x_component = diff.x / block_size
	var y_component = diff.y / block_size
	var z_component = diff.z / block_size
	
	var index = x_component + (y_component * max_x) + (z_component * max_x * max_y)
	index += aabb_offsets[aabb_index]
	return index
	
#	print("Pos: ", position)
#	print("AABB: ", aabb)
#	print("Diff: ", diff)
#	print(x_component, ' ', y_component, ' ', z_component)
#	print(max_x, ' ', max_y, ' ', max_z)
#	print("Index: ", index)


""" 
In this case, index is the index of the block data.
Block data is stored 3 per pixel.
Each pixel is two bytes (green channel spread between bytes).
This function updates path_collision_img.data.data (PoolByteArray),
and returns the pixel position.
"""
func set_collision_img_data(index:int, value:int) -> Vector2:
	var img_data = path_collision_img.data.data
	var pixel_index = index / 3
	var channel = index % 3
	var pixel_data_left  = img_data[pixel_index * 2]
	var pixel_data_right = img_data[pixel_index * 2 + 1]
	var full_pixel_data = pixel_data_left * 256 + pixel_data_right
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
	return Vector2(x,y)
