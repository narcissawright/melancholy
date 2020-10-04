extends Node
onready var geometry = $'../Geometry'
var vertex_data_octree:Dictionary

func _ready() -> void:
	create_octree_root_cube()
	

func create_octree_root_cube(): # big box covers entire level. the root of the octree.
	var aabb = geometry.get_aabb()
	var long = aabb.get_longest_axis_size()
	aabb = AABB(aabb.position, Vector3(long,long,long) ).grow(1) # grow is for padding
	# I guess I wanna force a cube shape
	
	vertex_data_octree = {
		"box" : aabb,   # axis-aligned bounding box
		"objects" : [], # list of dicts containing vertex data
		"children" : [] # list of child Octrees
	}
	
# returns the smallest node that contains the position
func search_octree(pos, root):
	if root.box.has_point(pos):
		var node = root
		while not node.children.empty():
			for child in node.children:
				if child.box.has_point(pos):
					node = child
					break
		return node
	else:
		return null # not found
		
#func add_to_tree(root, index):
#	var node = root
#	var grass_pos = grass_list[index].pos
#	while not node.children.empty():
#		for child in node.children:
#			if child.box.has_point(grass_pos):
#				node = child
#				break
#	node.objects.push_back(index)
#	compartmentalize(node)

# Octree splits into 8 smaller pieces
func compartmentalize(octree):
	if octree.objects.size() <= 64:
		return # if there is enough space for the new index, we don't need to compartmentalize.
	
	var new_boxes = []
	new_boxes.push_back(AABB(octree.box.position + (octree.box.size/2.0 * Vector3(0,0,0)), octree.box.size/2.0))
	new_boxes.push_back(AABB(octree.box.position + (octree.box.size/2.0 * Vector3(0,0,1)), octree.box.size/2.0))
	new_boxes.push_back(AABB(octree.box.position + (octree.box.size/2.0 * Vector3(0,1,0)), octree.box.size/2.0))
	new_boxes.push_back(AABB(octree.box.position + (octree.box.size/2.0 * Vector3(0,1,1)), octree.box.size/2.0))
	new_boxes.push_back(AABB(octree.box.position + (octree.box.size/2.0 * Vector3(1,0,0)), octree.box.size/2.0))
	new_boxes.push_back(AABB(octree.box.position + (octree.box.size/2.0 * Vector3(1,0,1)), octree.box.size/2.0))
	new_boxes.push_back(AABB(octree.box.position + (octree.box.size/2.0 * Vector3(1,1,0)), octree.box.size/2.0))
	new_boxes.push_back(AABB(octree.box.position + (octree.box.size/2.0 * Vector3(1,1,1)), octree.box.size/2.0))
	# Create 8 new children
	for j in range (0, new_boxes.size()):
		var new_octree = {
			"box" : new_boxes[j],
			"objects" : [],
			"children" : []
		}
		""" this part is needed pls fix once the equiv of grass_list exists. """
		#for i in range (0, octree.objects.size()):
		#	if new_octree.box.has_point(grass_list[octree.objects[i]].pos):
		#		new_octree.objects.push_back(octree.objects[i])
		octree.children.push_back(new_octree)
	octree.objects = []
	
	for child in octree.children: # handles rare cases of a compartmentalized box still holding too many indices
		compartmentalize(child)
