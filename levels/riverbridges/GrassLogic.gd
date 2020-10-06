extends Node
onready var geometry = $'../Geometry'
var vertex_data_octree:Dictionary
var grass_index:int = -1
var grass_surface:Array

func _ready() -> void:
	Events.connect("path_collision", self, "_on_path_collision")
	for i in range (geometry.mesh.get_surface_count()):
		if (geometry.mesh.get("surface_" + str(i+1) + "/name")) == "Grass":
			grass_index = i
	grass_surface = geometry.mesh.surface_get_arrays(grass_index)
#	print ("Vertices: ", grass_surface[ArrayMesh.ARRAY_VERTEX].size())
#	print ("Colors: ", grass_surface[ArrayMesh.ARRAY_COLOR].size())
#	print ("Indices: ", grass_surface[ArrayMesh.ARRAY_INDEX].size())
	
	create_octree_root_cube() # Initialize Octree
	
	# Populate Octree
	for i in range (grass_surface[ArrayMesh.ARRAY_VERTEX].size()):
		add_to_tree(vertex_data_octree, i, grass_surface[ArrayMesh.ARRAY_VERTEX][i])
	
	visualize_octree() # DEBUG

# debug viz
var debug_verts:PoolVector3Array
var debug_colors:PoolColorArray
func visualize_octree() -> void:
	var octree_viz:Array = []
	octree_viz.resize(Mesh.ARRAY_MAX)

	populate_arraymesh(vertex_data_octree)
	
	octree_viz[Mesh.ARRAY_VERTEX] = debug_verts
	octree_viz[Mesh.ARRAY_COLOR] = debug_colors
	var arr_mesh = ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, octree_viz)
	$OctreeViz.mesh = arr_mesh

# for debug viz
func populate_arraymesh(octree:Dictionary) -> void:
	debug_verts.append_array(get_aabb_vertices(octree.box))
	for _i in range (24):
		debug_colors.append(Color(0.6, 0.4, 1, 1))
	for i in range (octree.objects.size()):
		debug_verts.append(octree.objects[i].pos)
		debug_verts.append(octree.objects[i].pos + (Vector3.UP * 0.1))
		debug_colors.append(Color(0.6, 1, 0.3, 1))
		debug_colors.append(Color(0.6, 1, 0.3, 1))
	for i in range (octree.children.size()):
		populate_arraymesh(octree.children[i])

# for debug viz
func get_aabb_vertices(aabb:AABB) -> PoolVector3Array:
	var verts := PoolVector3Array() # 12 lines to make a cube. 24 vertices.
	verts.append(aabb.position + (aabb.size * Vector3(0,0,0)))
	verts.append(aabb.position + (aabb.size * Vector3(1,0,0)))
	verts.append(aabb.position + (aabb.size * Vector3(1,0,0)))
	verts.append(aabb.position + (aabb.size * Vector3(1,1,0)))
	verts.append(aabb.position + (aabb.size * Vector3(1,0,0)))
	verts.append(aabb.position + (aabb.size * Vector3(1,0,1)))
	verts.append(aabb.position + (aabb.size * Vector3(0,0,0)))
	verts.append(aabb.position + (aabb.size * Vector3(0,1,0)))
	verts.append(aabb.position + (aabb.size * Vector3(0,1,0)))
	verts.append(aabb.position + (aabb.size * Vector3(1,1,0)))
	verts.append(aabb.position + (aabb.size * Vector3(0,1,0)))
	verts.append(aabb.position + (aabb.size * Vector3(0,1,1)))
	verts.append(aabb.position + (aabb.size * Vector3(0,0,0)))
	verts.append(aabb.position + (aabb.size * Vector3(0,0,1)))
	verts.append(aabb.position + (aabb.size * Vector3(0,0,1)))
	verts.append(aabb.position + (aabb.size * Vector3(1,0,1)))
	verts.append(aabb.position + (aabb.size * Vector3(0,0,1)))
	verts.append(aabb.position + (aabb.size * Vector3(0,1,1)))
	verts.append(aabb.position + (aabb.size * Vector3(0,1,1)))
	verts.append(aabb.position + (aabb.size * Vector3(1,1,1)))
	verts.append(aabb.position + (aabb.size * Vector3(1,1,0)))
	verts.append(aabb.position + (aabb.size * Vector3(1,1,1)))
	verts.append(aabb.position + (aabb.size * Vector3(1,0,1)))
	verts.append(aabb.position + (aabb.size * Vector3(1,1,1)))
	return verts

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

const GRASS_HURT_DIST = 0.3
func _on_path_collision(pos:Vector3, impact:float):
	var node = search_octree(pos, vertex_data_octree)
	var axis_aligned_checks = PoolVector3Array() # we check 6 axis aligned points to find nearby grass containers.
	axis_aligned_checks.push_back(Vector3(-GRASS_HURT_DIST, 0, 0))
	axis_aligned_checks.push_back(Vector3( GRASS_HURT_DIST, 0, 0)) 
	axis_aligned_checks.push_back(Vector3(0, -GRASS_HURT_DIST/2.5, 0)) 
	axis_aligned_checks.push_back(Vector3(0,  GRASS_HURT_DIST/2.5, 0))
	axis_aligned_checks.push_back(Vector3(0, 0, -GRASS_HURT_DIST))
	axis_aligned_checks.push_back(Vector3(0, 0,  GRASS_HURT_DIST))
	var grass = find_grass_vertices(pos, axis_aligned_checks, node) # finds adjacent grass
	if grass.size() > 0:
		write_dirt_path(pos, grass, impact)
		
func write_dirt_path(pos:Vector3, grass:Array, impact:float) -> void:
	for i in range (0, grass.size()): # for each grass vertex
		var dist = pos.distance_to(grass[i].pos) # find dist from collision point to grass vertex
		if dist < GRASS_HURT_DIST: # if dist is within radius, write dirt
			
			var dmg = 0.0
			
			var value = clamp(grass_surface[ArrayMesh.ARRAY_COLOR][grass[i].index].g - 0.5, 0.0, 1.0)
			grass_surface[ArrayMesh.ARRAY_COLOR][grass[i].index].g = value
	
	# This is so obnoxious
	var dupe = geometry.mesh.duplicate()
	var mat = geometry.mesh.surface_get_material(grass_index)
	dupe.surface_remove(grass_index)
	dupe.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, grass_surface)
	grass_index = dupe.get_surface_count() - 1
	dupe.surface_set_material(grass_index, mat)
	geometry.mesh = dupe

func find_grass_vertices(pos, axis_aligned_checks, node):
	var boxes = []
	boxes.push_back(node.objects) # push the collision point box grass into the array
	
	for i in range (axis_aligned_checks.size()): # for each axis aligned check
		if !node.box.has_point(pos + axis_aligned_checks[i]): # if the new point to check isn't in the collision point box
			var box = search_octree(pos + axis_aligned_checks[i], vertex_data_octree) # find where it is
			# if the box ends up out of bounds entirely, typeof(box) won't be > 0
			if typeof(box) > 0:
				if boxes.find(box.objects) == -1 and box.objects.size() > 0: # if it isn't already in the boxes array, and has size
					boxes.push_back(box.objects) # add it
	return flatten(boxes) # return all the grass indices in a single array
	
# 2D array -> 1D array
static func flatten(arr):
	var result = []
	for a in arr:
		for x in a:
			result.append(x)
	return result
