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
	
	# Transform data into signed 16bit ints
	var data = PoolByteArray()
	for i in range (aabb_array.size()):
		var values = [
			aabb_array[i].position.x, 
			aabb_array[i].position.y, 
			aabb_array[i].position.z, 
			aabb_array[i].size.x, 
			aabb_array[i].size.y, 
			aabb_array[i].size.z
		]
		for j in range (values.size()):
			# warning-ignore:integer_division
			var left_byte = int(values[j]) / 256
			if sign(values[j]) == -1:
				left_byte |= 0b10000000
			var right_byte = int(abs(values[j])) % 256
			data.append(left_byte)
			data.append(right_byte)

	print (data.hex_encode())
	
	# Create image from data
	var aabb_data_img = Image.new()                             # 16 bits per channel
	aabb_data_img.create_from_data(2, aabb_array.size(), false, Image.FORMAT_RGBH, data)
	var aabb_data_tex = ImageTexture.new()
	aabb_data_tex.create_from_image(aabb_data_img, 0)
	
	$AABB_TEXTURE.get_surface_material(0).albedo_texture = aabb_data_tex
	# I'm assuming I did this correctly.
	# Next step.......
	# - Create the path image
	# - Find a way to calculate which bounding box contains a 3d position (in the shader)
	# - Try edge cases like the position not existing in any of the bounding boxes (in the shader AND in gdscript)
	# - Add a check that none of the AABBs are overlapping before I initialize the aabb array
	# - Write image data
	# - Draw dirt from shader

func toggle_debug_view(state:bool) -> void:
	aabbs.visible = state

func _on_path_collision(_position:Vector3, _velocity_length:float) -> void:
	pass
