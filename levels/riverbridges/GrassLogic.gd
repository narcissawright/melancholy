extends Node

# Materials
var grass_material:Material # grass floor surface that has shader params I need to set from here.

# Data
var grass_data:Resource

const block_size:float = 0.5
var debug_mode = false

func _ready() -> void:
	# Signals

	# NOTE: GrassLogic must be a HIGHER SIBLING to get the 
	# grass_material signal to come in in the proper order!
	Events.connect("grass_surface",       self, "obtained_grass_surface")
	Events.connect("path_collision",      self, "on_path_collision")
	Events.connect("quit_game",           self, "on_quit")
	Events.connect("mysterious_mushroom", self, "clear_grass_data")
	Events.connect("player_location",     self, "pass_player_location_to_shader")
#	Events.connect("debug_view",          self, "toggle_debug_view")
	
	# To recalculate textures after making changes, run create_data_images()
	var f = File.new()
	if f.file_exists("user://" + Level.path + "grass_data.tres"):
		grass_data = load("user://" + Level.path + "grass_data.tres")
	else:
		create_data_images()

func obtained_grass_surface(level_mesh, surface_index) -> void:
	grass_material = level_mesh.surface_get_material(surface_index)
	
	# Set Shader Params
	# TODO: don't use hardcoded nodepath for this
	$"../picture_frame/grass_aabb_data_tex".get_surface_material(0).albedo_texture = grass_data.aabb_tex
	#$path_collision_data_tex.get_surface_material(0).albedo_texture = grass_data.path_collision_tex
	grass_material.set_shader_param('collision_data', grass_data.path_collision_tex)
	grass_material.set_shader_param('block_size', block_size)
	grass_material.set_shader_param("aabb_data", grass_data.aabb_tex)

	# Create Flora
	create_flora(level_mesh, surface_index)

func create_data_images() -> void:
	grass_data = load("res://levels/grass_data_empty.tres").duplicate()
	
	var blocks_per_cubic_meter = pow((1.0 / block_size), 3)
	
	# Obtain data from AABBs
	for child in $AABBs.get_children():
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

#func toggle_debug_view(state:bool) -> void:
#	debug_mode = state
#	$AABBs.visible = state

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


static func get_normal(v1:Vector3, v2:Vector3, v3:Vector3) -> Vector3:
	return (v1-v2).cross(v1-v3).normalized()

static func tri_area(v1:Vector3, v2:Vector3, v3:Vector3) -> float:
	return (v2 - v1).cross(v3 - v1).length() / 2.0

# Find random point on Triangle
static func sample_tri(p1:Vector3, p2:Vector3, p3:Vector3) -> Vector3:
	var a = randf()
	var b = randf()
	var v1 = p2 - p1
	var v2 = p3 - p1
	while a + b > 1:
		a = randf()
		b = randf()
	return p1 + a*v1 + b*v2

const grass_multimesh = preload('GrassMultiMesh.tscn')
const GRASS_COLORS = [
	Color(0.02, 0.25, 0.08),
	Color(0.03, 0.23, 0.05),
	Color(0.02, 0.22, 0.12)
#	Color(0.09, 0.48, 0.22), 
#	Color(0.17, 0.42, 0.4), 
#	Color(0.25, 0.39, 0.15), 
#	Color(0.09, 0.28, 0.14)
	]
const GRASS_THICKNESS = 30

func create_flora(level_mesh, surface_index) -> void:
	
	# One MultiMesh per AABB
	for i in range (grass_data.aabb_array.size()):
		var mm_instance = grass_multimesh.instance()
		mm_instance.name = 'multimesh_' + str(i)
		mm_instance.multimesh.color_format = MultiMesh.COLOR_8BIT
		$MultiMeshes.add_child(mm_instance)
	
	# Get geometry data for the grass surface:
	var vertices = level_mesh.surface_get_arrays(surface_index)[ArrayMesh.ARRAY_VERTEX]
	var indices  = level_mesh.surface_get_arrays(surface_index)[ArrayMesh.ARRAY_INDEX]

	# Need to calc the total instance count based on surface area of all triangles
	# But I should discount triangles that are not in a grass bounding box
	# And I should use a separate multimesh for each bounding box
	
	# Presumably I only need to check if one of the three verts are inside of the bounding box
	# as the other two should be, by design (by me placing the bounding boxes to envelop entire
	# vertex islands...
	
	# I guess I need to store transform and color
	# for every blade of grass
	# but separate them into different groups based on AABB
	# probably three arrays of dicts
	
#	var multimesh_data = [
#		[
#			{
#				xform: Transform(),
#				color: Color()
#			},
#		],
#		[ etc

	var multimesh_data:Array = []
	for _i in range (grass_data.aabb_array.size()):
		multimesh_data.append([])
	
	for i in range (0, indices.size(), 3): # for each triangle
		var relevant_aabb = determine_relevant_aabb(vertices[indices[i]])
		if relevant_aabb > -1: # first vertex of surface triangle exists in bounding box
			var area:float = tri_area(vertices[indices[i]], vertices[indices[i+1]], vertices[indices[i+2]])
			for _j in range(floor(area * GRASS_THICKNESS)): 
				var color = GRASS_COLORS[randi() % GRASS_COLORS.size()]
				var pos = sample_tri(vertices[indices[i]], vertices[indices[i+1]], vertices[indices[i+2]])
				var basis = Basis()
				var scale = 1.0 + randf()
				basis = basis.scaled(Vector3(scale, scale, scale))
				var rotation = randf() * TAU
				basis = basis.rotated(Vector3.UP, rotation)
				multimesh_data[relevant_aabb].append({"xform": Transform(basis, pos), "color": color})

	var total_instance_count = 0
	for i in range (multimesh_data.size()):
		var multimesh = $MultiMeshes.get_child(i).multimesh
		multimesh.instance_count = multimesh_data[i].size()
		total_instance_count += multimesh.instance_count
		for j in range (multimesh.instance_count):
			multimesh.set_instance_transform(j, multimesh_data[i][j].xform)
			multimesh.set_instance_color(j, multimesh_data[i][j].color)

	print ("Total Grass Blades: ", total_instance_count)
	
const grassblade = preload("GrassBlade.material")
func pass_player_location_to_shader(location:Vector3) -> void:
	grassblade.set_shader_param("player_position", location)
