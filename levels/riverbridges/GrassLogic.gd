extends Node
onready var aabb_container = $AABBs

# Materials
var grass_material:Material # grass floor surface that has shader params I need to set from here.

# Data
var grass_data:Resource

const block_size:float = 0.5
var debug_mode = false

func _ready() -> void:
	aabb_container.visible = false # hide debug thing
	
	# Signals
	Events.connect("grass_material",      self, "process_grass")
	Events.connect("debug_view",          self, "toggle_debug_view")
	Events.connect("path_collision",      self, "on_path_collision")
	Events.connect("quit_game",           self, "on_quit")
	Events.connect("mysterious_mushroom", self, "clear_grass_data")
	
	# To recalculate textures after making changes, run create_data_images()
	var f = File.new()
	if f.file_exists("user://" + Level.path + "grass_data.tres"):
		grass_data = load("user://" + Level.path + "grass_data.tres")
	else:
		create_data_images()

	
func process_grass(grass_mat) -> void:
	grass_material = grass_mat
	
	# Set shader params
	$"../picture_frame/grass_aabb_data_tex".get_surface_material(0).albedo_texture = grass_data.aabb_tex
	#$DebugTexture2.get_surface_material(0).albedo_texture = grass_data.path_collision_tex
	grass_material.set_shader_param('collision_data', grass_data.path_collision_tex)
	grass_material.set_shader_param('block_size', block_size)
	grass_material.set_shader_param("aabb_data", grass_data.aabb_tex)

func create_data_images() -> void:
	grass_data = load("res://levels/grass_data_empty.tres").duplicate()
	
	var blocks_per_cubic_meter = pow((1.0 / block_size), 3)
	
	# Obtain data from AABBs
	for child in aabb_container.get_children():
		grass_data.aabb_array.append(AABB(child.position, child.size))
		
	# Sort AABBs by volume to do less containment checks on average
	grass_data.aabb_array.sort_custom(self, "sort_by_volume")
	
	# Calculate offsets
	var cubic_meters:float = 0
	var aabb_data_img = Image.new()
	var data := PoolByteArray()
	for i in range (grass_data.aabb_array.size()):
		# Each pass of this loop I store the data offset (how far I have to jump in the collision_data to reach next bounding box)
		grass_data.aabb_offsets.append(cubic_meters * blocks_per_cubic_meter)
		
		# This is what I need to store in the aabb_data_img
		var relevant_data:Array = []
		relevant_data.append(grass_data.aabb_array[i].position.x) #RG 1
		relevant_data.append(grass_data.aabb_array[i].position.y) #RG 2
		relevant_data.append(grass_data.aabb_array[i].position.z) #RG 3
		relevant_data.append(grass_data.aabb_array[i].size.x)     #RG 4
		relevant_data.append(grass_data.aabb_array[i].size.y)     #RG 5
		relevant_data.append(grass_data.aabb_array[i].size.z)     #RG 6
		
		# add the AABB position and size data to the img
		for j in range (relevant_data.size()):
			# Add 32768 so I don't have to store negative 16bit numbers (headache)
			# This gets subtracted in shader later to get signed int.
			var stored_value := int(relevant_data[j]) + 32768
			data.append(stored_value / 256) # R 1-6
			data.append(stored_value % 256) # G 1-6
			
		# Offset can be large, so I store it across 4 bytes.
		var offset = int(cubic_meters * pow((1.0 / block_size), 3))
		data.append((offset / 16777216) % 256) # R 7
		data.append((offset / 65536) % 256)    # G 7
		data.append((offset / 256) % 256)      # R 8
		data.append( offset % 256)             # G 8
		cubic_meters += grass_data.aabb_array[i].get_area()
	
	aabb_data_img.create_from_data(8, grass_data.aabb_array.size(), false, Image.FORMAT_RG8, data)
	# Image.FORMAT_RG8 does not do an sRGB conversion, so the data that goes in can be 
	# safely converted back into bytes in the shader (with a little math).

	# ImageTexture gets passed to shader.
	grass_data.aabb_tex = ImageTexture.new()
	grass_data.aabb_tex.create_from_image(aabb_data_img, 0)

	# Calculate image height
	var height := int(ceil(cubic_meters * blocks_per_cubic_meter / 8192.0 / 4.0))
	
	# Populate image with noise
#	data = PoolByteArray()
#	for _i in range (8192 * height * 4):
#		data.append(randi() % 256)
		
	# Create image
	grass_data.path_collision_img = Image.new()
	grass_data.path_collision_img.create(8192, height, false, Image.FORMAT_RGBA8)
	# FORMAT_RGBA8 does do srgb conversion but I can convert it back in the shader without much hassle.
	
	# Create texture.
	grass_data.path_collision_tex = ImageTexture.new()
	grass_data.path_collision_tex.create_from_image(grass_data.path_collision_img, 0)

	save_grass_data()

static func sort_by_volume(a:AABB, b:AABB) -> bool:
	if a.get_area() > b.get_area():
		return true
	return false

func toggle_debug_view(state:bool) -> void:
	debug_mode = state
	aabb_container.visible = state

func determine_relevant_aabb(point:Vector3) -> int:
	for i in range (grass_data.aabb_array.size()):
		if grass_data.aabb_array[i].has_point(point):
			return i
	return -1

func on_path_collision(position:Vector3, velocity_length:float) -> void:
	# Find the 8 nearest blocks to this position

	# Snap to nearest block
	var rounded_pos:Vector3 = (position / block_size).round() * block_size # nearest 
	
	# use the difference between the position and the snapped position to find relevant adjacent blocks
	var x_sign := int(sign(position.x - rounded_pos.x));
	var y_sign := int(sign(position.y - rounded_pos.y));
	var z_sign := int(sign(position.z - rounded_pos.z));

	# Try these positions (some might be duplicates due to sign being zero)
	# Sign can be zero when the surface triangle aligns perfectly with block size.
	var try_positions:Array = [
		rounded_pos + Vector3(     0,      0, z_sign) * block_size,
		rounded_pos + Vector3(     0, y_sign,      0) * block_size,
		rounded_pos + Vector3(     0, y_sign, z_sign) * block_size,
		rounded_pos + Vector3(x_sign,      0,      0) * block_size,
		rounded_pos + Vector3(x_sign,      0, z_sign) * block_size,
		rounded_pos + Vector3(x_sign, y_sign,      0) * block_size,
		rounded_pos + Vector3(x_sign, y_sign, z_sign) * block_size
	]
	
	# Add relevant positions to array
	var positions:Array = [rounded_pos]
	for i in range (try_positions.size()):
		if not positions.has(try_positions[i]):
			positions.append(try_positions[i])
	
	if debug_mode:
		# Draws the relevant boxes for this write
		$DebugView.draw_positions(positions, block_size) 
	
	# Gather the pixel positions in the collision_data_img that need to update in the texture.
	var pixel_positions := []
	for i in range (positions.size()):
		var aabb_index = determine_relevant_aabb(positions[i])
		if aabb_index == -1:
			continue # No relevant AABB found, stop here.
		
		# Calculate index
		var index:int = get_data_index(positions[i], aabb_index)
		
		# Use distance and velocity to determine how much to change the grass/dirt value
		var distance = (position - positions[i]).length()
		# I think 1.0 might be wrong here, might want block_size
		var value:int = int((1.0 - distance) * velocity_length)
		if value > 0:
			var pixel:Vector2 = set_collision_img_data(index, value)
			if not pixel_positions.has(pixel):
				# Some writes will be writing to different channels of the same pixel, as they store different block data.
				# I make sure I don't have duplicate pixel_positions in this array, to be used for updating texture.
				pixel_positions.append(pixel)
	
	# Update texture.
	for i in range (pixel_positions.size()):
		# I would like to support doing writes of 2 pixels at once if they are adjacent
		# but I want to know if that would increase performance
		VisualServer.texture_set_data_partial(grass_data.path_collision_tex.get_rid(), grass_data.path_collision_img, pixel_positions[i].x, pixel_positions[i].y, 1, 1, pixel_positions[i].x, pixel_positions[i].y, 0)

# Finds the index in the PoolByteArray that is relevant for this 3D position.
func get_data_index(position:Vector3, aabb_index:int) -> int:
	var aabb:AABB = grass_data.aabb_array[aabb_index]
	var diff:Vector3 = position - aabb.position
	var max_x := int(aabb.size.x / block_size)
	var max_y := int(aabb.size.y / block_size)
	diff /= block_size
	var index := int(diff.x + (diff.y * max_x) + (diff.z * max_x * max_y))
	index += grass_data.aabb_offsets[aabb_index]
	return index
 
# This function updates path_collision_img.data.data (PoolByteArray),
# and returns the pixel position.
func set_collision_img_data(index:int, value:int) -> Vector2:
	var img_data:PoolByteArray = grass_data.path_collision_img.data.data
	var pixel_data:int = img_data[index]
	pixel_data = int(min(pixel_data + value, 255))
	img_data.set(index, pixel_data)
	grass_data.path_collision_img.data.data = img_data
	var y:int = index / 4 / 8192
	var x:int = index / 4 % 8192
	return Vector2(x,y)
	
func on_quit() -> void:
	save_grass_data()
	
func save_grass_data():
	var dir = Directory.new()
	assert (dir.open("user://") == OK)
	if not dir.dir_exists(Level.path):
		dir.make_dir_recursive(Level.path)
	ResourceSaver.save("user://" + Level.path + "grass_data.tres", grass_data)

func clear_grass_data():
	var size:int = grass_data.path_collision_img.data.data.size()
	var data := PoolByteArray()
	data.resize(size)
	grass_data.path_collision_img.data.data = data
	grass_data.path_collision_tex.create_from_image(grass_data.path_collision_img, 0)
