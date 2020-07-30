extends MeshInstance 

# Properties
var velocity:Vector3 # set by creator
var lifespan = 5.0

# Collision
var query := PhysicsShapeQueryParameters.new()
var shape := SphereShape.new()

func _ready() -> void:
	query.transform = global_transform
	query.collide_with_areas = false
	query.collision_mask = Layers.player | Layers.solid
	shape.radius = 0.1
	query.set_shape(shape)

func _physics_process(t: float) -> void:
	var move_vec:Vector3 = velocity * t
	query.transform = global_transform
	var space_state = get_world().direct_space_state
	var result = space_state.cast_motion(query, move_vec)
	if result[1] == 1:
		# projectile did not hit anything
		translation += move_vec
	else:
		translation += move_vec * result[1]
		query.transform = transform
		hit(space_state)
	
	lifespan -= t
	if lifespan <= 0:
		queue_free()
		
	velocity.y += (Game.GRAVITY * 0.05 ) * t
	
func hit(space_state):
	var collisions = space_state.intersect_shape(query)
	for i in range (collisions.size()):
		if collisions[i].collider.collision_layer == Layers.player:
			Game.player.set_locked(10)
	queue_free()
