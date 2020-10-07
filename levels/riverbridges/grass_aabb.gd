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

func set_pos(pos:Vector3) -> void:
	position = pos.round()
	update_mesh()
	
func set_size(new_size:Vector3) -> void:
	if new_size.x < 1: new_size.x = 1
	if new_size.y < 1: new_size.y = 1
	if new_size.z < 1: new_size.z = 1
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
	
