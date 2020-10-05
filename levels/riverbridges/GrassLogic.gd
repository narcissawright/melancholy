extends Node
onready var geometry = $'../Geometry'
var vertex_data_octree:Dictionary
var grass_surface:Array

func _ready() -> void:
	var grass_idx = -1
	for i in range (geometry.mesh.get_surface_count()):
		if (geometry.mesh.get("surface_" + str(i+1) + "/name")) == "Grass":
			grass_idx = i
	print ("Grass index is ", grass_idx)
	grass_surface = geometry.mesh.surface_get_arrays(grass_idx)
	print (grass_surface[ArrayMesh.ARRAY_VERTEX].size())
	print ("---")
	print (grass_surface[ArrayMesh.ARRAY_COLOR].size())
	print ("---")
	print (grass_surface[ArrayMesh.ARRAY_INDEX].size())
	
	
	create_octree_root_cube()
	
	for i in range (grass_surface[ArrayMesh.ARRAY_VERTEX].size()):
		add_to_tree(vertex_data_octree, i, grass_surface[ArrayMesh.ARRAY_VERTEX][i])
		
	#print (vertex_data_octree)
	draw_octree(vertex_data_octree)

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

# passes in
# - the octree
# - the index (where is it in the VERTEX and COLOR arrays, NOT the INDEX array)
# - the position (Vector3)
func add_to_tree(root, index, pos):
	var node = root
	while not node.children.empty():
		for child in node.children:
			if child.box.has_point(pos):
				node = child
				break
	node.objects.push_back({"index": index, "pos": pos})
	compartmentalize(node)

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
		# Loop over all vertices in the current octree before it was split, 
		# and push them into the appropriate child octree.
		for i in range (0, octree.objects.size()):
			if new_octree.box.has_point(octree.objects[i].pos):
				new_octree.objects.push_back(octree.objects[i])
		# new_octree has finished populating at this point.
		octree.children.push_back(new_octree)
	# Once we have reached this point, all objects in the current scope should have been reassigned
	octree.objects = []
	for child in octree.children: # handles rare cases of a compartmentalized box still holding too many indices
		compartmentalize(child)

func draw_octree(octree) -> void:
	draw_aabb(octree.box)
	for i in range (octree.objects.size()):
		Debug.draw.begin(Mesh.PRIMITIVE_LINES, null)
		Debug.draw.set_color(Color(0.6, 1, 0.3, 1))
		Debug.draw.add_vertex(octree.objects[i].pos)
		Debug.draw.add_vertex(octree.objects[i].pos + (Vector3.UP * 0.1))
		Debug.draw.end()
	for i in range (octree.children.size()):
		draw_octree(octree.children[i])

# Draw Axis-Aligned Bounding Box (debug function)
func draw_aabb(aabb):
	Debug.draw.begin(Mesh.PRIMITIVE_LINES, null) # begin ImmediateGeometry creation
	Debug.draw.set_color(Color(0.6, 0.4, 1, 1))
	# 12 lines create a cube wireframe.
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(0,0,0)))
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(1,0,0)))
	
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(1,0,0)))
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(1,1,0)))
	
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(1,0,0)))
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(1,0,1)))
	
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(0,0,0)))
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(0,1,0)))
	
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(0,1,0)))
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(1,1,0)))
	
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(0,1,0)))
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(0,1,1)))
	
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(0,0,0)))
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(0,0,1)))
	
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(0,0,1)))
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(1,0,1)))
	
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(0,0,1)))
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(0,1,1)))
	
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(0,1,1)))
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(1,1,1)))
	
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(1,1,0)))
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(1,1,1)))
	
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(1,0,1)))
	Debug.draw.add_vertex(aabb.position + (aabb.size * Vector3(1,1,1)))
	
	Debug.draw.end()
