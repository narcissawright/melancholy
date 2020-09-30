extends Spatial

onready var raystart = $RayStart
onready var forward_collision = $LedgeGrab/Forward
onready var vertical_collision = $LedgeGrab/Vertical
onready var ledge_detector = $LedgePos/LedgePos

var query := PhysicsShapeQueryParameters.new() # Collision Query for ledgegrab height

func _ready() -> void:
	query.collision_mask = Layers.solid

func vertical_raycast() -> Dictionary:
	var from = raystart.global_transform.origin
	var to =   raystart.global_transform.origin + Vector3(0, -0.31, 0)
	var result = get_world().direct_space_state.intersect_ray(from, to, [], Layers.solid)
	if result.size() > 0:
		return { "is_colliding": true, "height": result.position.y }
	return { "is_colliding": false }

func horizontal_raycast(height:float) -> Dictionary:
	# the goal here is to use the very small height offset to always get a collision. 
	
	var xform = Player.transform
	var leftright_offset:Vector3 = xform.basis.x * 0.1
	
	var from = Vector3(xform.origin.x, height - 0.001, xform.origin.z) + leftright_offset
	var to   = from - xform.basis.z
	var result1 = get_world().direct_space_state.intersect_ray(from, to, [], Layers.solid)
	
	from = Vector3(xform.origin.x, height - 0.001, xform.origin.z) - leftright_offset
	to   = from - xform.basis.z
	var result2 = get_world().direct_space_state.intersect_ray(from, to, [], Layers.solid)
	
	if not result1.empty() and not result2.empty():
		return {"hits": 2, "normal": (result1.normal + result2.normal) / 2.0, "position": (result1.position + result2.position) / 2.0}
	elif result1.empty() and result2.empty():
		return {"hits": 0}
	elif result1.empty():
		return {"hits": 1, "normal": result2.normal, "position": result2.position}
	else:
		return {"hits": 1, "normal": result1.normal, "position": result1.position}

func try_ledgegrab() -> Dictionary:
	var vray_result:Dictionary = vertical_raycast()
	if vray_result.is_colliding == false:
		return { "can_ledgegrab": false }
	
	var space_state = get_world().direct_space_state
	
	# Check that the space for the hands to be is clear
	query.set_shape(forward_collision.shape)
	query.transform = forward_collision.global_transform
	var result:Array = space_state.intersect_shape(query)
	if result.size() > 0:
		return { "can_ledgegrab": false }
	
	# Check that nothing is immediately above the player.
	query.set_shape(vertical_collision.shape)
	query.transform = vertical_collision.global_transform
	result = space_state.intersect_shape(query)
	if result.size() > 0:
		return { "can_ledgegrab": false }
	
	# Check that there is a surface below where the hands should grab.
	query.set_shape(ledge_detector.shape)
	query.transform = ledge_detector.global_transform
	result = space_state.intersect_shape(query)
	if result.size() == 0:
		return { "can_ledgegrab": false }
	
	return { "can_ledgegrab": true, "height": vray_result.height }
