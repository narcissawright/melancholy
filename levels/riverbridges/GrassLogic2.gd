extends Node
onready var aabbs = $AABBs

func _ready() -> void:
	Events.connect("debug_view", self, "toggle_debug_view")
	aabbs.visible = false
	
	var aabb_array = []
	for child in aabbs.get_children():
		aabb_array.append(child.position)
		aabb_array.append(child.size)
	
	var aabb_data_img = Image.new()
	aabb_data_img.create(2, aabb_array.size() / 2, false, Image.FORMAT_RGBH) # 16 bits per channel
	var aabb_data_tex = ImageTexture.new()
	aabb_data_tex.create_from_image(aabb_data_img, 0)
	
	print (aabb_array)
	#Events.connect("path_collision", self, "_on_path_collision")

func toggle_debug_view(state:bool) -> void:
	aabbs.visible = state

#	var height = ceil((aabb.size.x+1) * (aabb.size.y+1) * (aabb.size.z+1) / 1024.0)
#	path_collision_img = Image.new()
#	path_collision_img.create(1024, height, false, Image.FORMAT_L8)
#	path_collision_tex = ImageTexture.new()
#	path_collision_tex.create_from_image(path_collision_img, 0)
#	$TextureRect.texture = path_collision_tex
#	Level.get_node("level1/Geometry").get_surface_material(0).set_shader_param("collision_data", path_collision_tex)

