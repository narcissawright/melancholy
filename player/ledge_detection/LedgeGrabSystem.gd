extends Spatial

onready var raystart = $RayStart
onready var forward_collision = $LedgeGrab/Forward
onready var vertical_collision = $LedgeGrab/Vertical
onready var ledge_detector = $LedgePos/LedgePos

var query := PhysicsShapeQueryParameters.new() # Collision Query for ledgegrab height

func _ready() -> void:
	query.collision_mask = Layers.solid

""" Find a way to combine these two functions."""
func raycast_is_colliding() -> bool:
	var from = raystart.global_transform.origin
	var to =   raystart.global_transform.origin + Vector3(0, -0.31, 0)
	var result = get_world().direct_space_state.intersect_ray(from, to, [], Layers.solid)
	if result.size() > 0:
		return true
	return false
	
func grab_height() -> float:
	var from = raystart.global_transform.origin
	var to =   raystart.global_transform.origin + Vector3(0, -0.31, 0)
	var result = get_world().direct_space_state.intersect_ray(from, to, [], Layers.solid)
	if result.size() > 0:
		return result.position.y
	return 0.0 # this shouldn't run

func can_ledgegrab() -> bool:
	if not raycast_is_colliding():
		return false 
	
	var space_state = get_world().direct_space_state
	
	query.set_shape(forward_collision.shape)
	query.transform = forward_collision.global_transform
	var result:Array = space_state.intersect_shape(query)
	if result.size() > 0:
		return false 
		
	query.set_shape(vertical_collision.shape)
	query.transform = vertical_collision.global_transform
	result = space_state.intersect_shape(query)
	if result.size() > 0:
		return false
	
	query.set_shape(ledge_detector.shape)
	query.transform = ledge_detector.global_transform
	result = space_state.intersect_shape(query)
	if result.size() == 0:
		return false
	
	return true
