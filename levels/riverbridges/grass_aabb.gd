tool
extends MeshInstance

var lines_mat = preload("res://global/debug/DebugLinesMaterial.tres")
var fill_mat = preload("res://global/debug/DebugFillMaterial.tres")

export var position := Vector3.ZERO setget set_pos
export var size := Vector3.ONE setget set_size

#func _ready() -> void:
#	set_notify_transform(true)
#
#func _notification (what:int) -> void:
#	#print("Hello?")
#	if what == NOTIFICATION_TRANSFORM_CHANGED:
#		#print( "Transform Changed")
#		set_pos(translation)

func is_overlapping(test_pos:Vector3, test_size:Vector3) -> bool:
	if not is_inside_tree():
		# prevent editor from throwing errors
		# when an instanced scene's tool script first runs
		# (runs because it populates the export vars)
		return false
	for child in get_parent().get_children():
		if child != self:
			if AABB(test_pos, test_size).intersects(AABB(child.position, child.size)):
				print ("AABBs overlap.")
				return true
	return false

func set_pos(new_pos:Vector3) -> void:
	new_pos = new_pos.round()
	if not is_overlapping(new_pos, size):
		position = new_pos
		update_mesh()
	
func set_size(new_size:Vector3) -> void:
	if new_size.x < 1: new_size.x = 1
	if new_size.y < 1: new_size.y = 1
	if new_size.z < 1: new_size.z = 1
	new_size = new_size.round()
	if not is_overlapping(position, new_size):
		size = new_size.round()
		update_mesh()
	
func update_mesh() -> void:
	
	# LINES mesh
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	var verts := PoolVector3Array()
	var pos = position
	verts.append(pos + (size * Vector3(0,0,0)))
	verts.append(pos + (size * Vector3(1,0,0)))
	verts.append(pos + (size * Vector3(1,0,0)))
	verts.append(pos + (size * Vector3(1,1,0)))
	verts.append(pos + (size * Vector3(1,0,0)))
	verts.append(pos + (size * Vector3(1,0,1)))
	verts.append(pos + (size * Vector3(0,0,0)))
	verts.append(pos + (size * Vector3(0,1,0)))
	verts.append(pos + (size * Vector3(0,1,0)))
	verts.append(pos + (size * Vector3(1,1,0)))
	verts.append(pos + (size * Vector3(0,1,0)))
	verts.append(pos + (size * Vector3(0,1,1)))
	verts.append(pos + (size * Vector3(0,0,0)))
	verts.append(pos + (size * Vector3(0,0,1)))
	verts.append(pos + (size * Vector3(0,0,1)))
	verts.append(pos + (size * Vector3(1,0,1)))
	verts.append(pos + (size * Vector3(0,0,1)))
	verts.append(pos + (size * Vector3(0,1,1)))
	verts.append(pos + (size * Vector3(0,1,1)))
	verts.append(pos + (size * Vector3(1,1,1)))
	verts.append(pos + (size * Vector3(1,1,0)))
	verts.append(pos + (size * Vector3(1,1,1)))
	verts.append(pos + (size * Vector3(1,0,1)))
	verts.append(pos + (size * Vector3(1,1,1)))
	var colors := PoolColorArray()
	for _i in range (24):
		colors.append(Color(0.6, 0.4, 1, 1))
	
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_COLOR] = colors
	var arr_mesh = ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arr)
	arr_mesh.surface_set_material(0, lines_mat)
	
	# FILL mesh
	arr = []
	arr.resize(Mesh.ARRAY_MAX)
	verts = PoolVector3Array()
	verts.append(pos + (size * Vector3(0,0,1)))
	verts.append(pos + (size * Vector3(1,0,1)))
	verts.append(pos + (size * Vector3(1,1,1)))
	verts.append(pos + (size * Vector3(0,0,1)))
	verts.append(pos + (size * Vector3(1,1,1)))
	verts.append(pos + (size * Vector3(0,1,1)))
	verts.append(pos + (size * Vector3(1,0,1)))
	verts.append(pos + (size * Vector3(1,0,0)))
	verts.append(pos + (size * Vector3(1,1,0)))
	verts.append(pos + (size * Vector3(1,0,1)))
	verts.append(pos + (size * Vector3(1,1,0)))
	verts.append(pos + (size * Vector3(1,1,1)))
	verts.append(pos + (size * Vector3(1,0,0)))
	verts.append(pos + (size * Vector3(0,0,0)))
	verts.append(pos + (size * Vector3(0,1,0)))
	verts.append(pos + (size * Vector3(1,0,0)))
	verts.append(pos + (size * Vector3(0,1,0)))
	verts.append(pos + (size * Vector3(1,1,0)))
	verts.append(pos + (size * Vector3(0,0,0)))
	verts.append(pos + (size * Vector3(0,0,1)))
	verts.append(pos + (size * Vector3(0,1,1)))
	verts.append(pos + (size * Vector3(0,0,0)))
	verts.append(pos + (size * Vector3(0,1,1)))
	verts.append(pos + (size * Vector3(0,1,0)))
	verts.append(pos + (size * Vector3(0,1,1)))
	verts.append(pos + (size * Vector3(1,1,1)))
	verts.append(pos + (size * Vector3(1,1,0)))
	verts.append(pos + (size * Vector3(0,1,1)))
	verts.append(pos + (size * Vector3(1,1,0)))
	verts.append(pos + (size * Vector3(0,1,0)))
	verts.append(pos + (size * Vector3(1,0,1)))
	verts.append(pos + (size * Vector3(0,0,0)))
	verts.append(pos + (size * Vector3(1,0,0)))
	verts.append(pos + (size * Vector3(1,0,1)))
	verts.append(pos + (size * Vector3(0,0,1)))
	verts.append(pos + (size * Vector3(0,0,0)))
	
	arr[Mesh.ARRAY_VERTEX] = verts
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	arr_mesh.surface_set_material(1, fill_mat)
	
	mesh = arr_mesh
	