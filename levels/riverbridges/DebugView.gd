extends MeshInstance

func draw_positions(positions:Array, size:float) -> void:
	# LINES mesh
	var arr = []
	arr.resize(Mesh.ARRAY_MAX)
	var verts := PoolVector3Array()
	var colors := PoolColorArray()
	for i in range (positions.size()):
		var pos = positions[i] - Vector3(size, size, size) * 0.5
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
		for _j in range (24):
			colors.append(Color(0.6, 0.4, 1, 1))
	
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_COLOR] = colors
	var arr_mesh = ArrayMesh.new()
	arr_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arr)
	arr_mesh.surface_set_material(0, Debug.lines_mat)
	
	# FILL mesh
	arr = []
	arr.resize(Mesh.ARRAY_MAX)
	verts = PoolVector3Array()
	
	for i in range (positions.size()):
		var pos = positions[i] - Vector3(size, size, size) * 0.5
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
	arr_mesh.surface_set_material(1, Debug.fill_mat)
	
	mesh = arr_mesh
