extends MultiMeshInstance

func _ready() -> void:
	for x in range (10):
		multimesh.set_instance_transform(x, Transform(Basis(), Vector3(x / 10.0, 0, 0)))
