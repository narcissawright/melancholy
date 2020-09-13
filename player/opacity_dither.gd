extends MeshInstance

var material
func _ready() -> void:
	material = get_surface_material(0)
	pause_mode = PAUSE_MODE_PROCESS

func _process(_t:float) -> void:
	var length_squared = minimum_distance(
		Player.position, 
		Player.position + Vector3.UP * 1.8, 
		MainCam.global_transform.origin)
	
	# close length is 0.2, far length is 0.4.
	var opacity = clamp(inverse_lerp(0.04, 0.16, length_squared), 0.0, 1.0)
	
	material.set_shader_param("opacity", opacity)
	material.next_pass.set_shader_param("opacity", opacity)

func minimum_distance(v:Vector3, w:Vector3, p:Vector3) -> float:
	# how close is point p to line segment vw?
	# returns length_squared instead of length for performance.
	var l2:float = (w-v).dot(w-v)
	if (l2 == 0.0): return (v-p).length_squared() # v == w case
	var t:float = max(0, min(1, (p-v).dot(w-v) / l2));
	var projection:Vector3 = v + t * (w - v); # Projection falls on the segment
	return (projection - p).length_squared();
