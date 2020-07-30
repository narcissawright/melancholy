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
		hit(space_state, t)
	
	lifespan -= t
	if lifespan <= 0:
		queue_free()
		
	velocity.y += (Game.GRAVITY * 0.5 ) * t
	
func hit(space_state, t):
	var shieldhit = false
	var playerhit = false
	
	var collisions:Array = space_state.intersect_shape(query)
	for i in range (collisions.size()):
		if collisions[i].collider.collision_layer == Layers.player:
			playerhit = true
			if collisions[i].shape != 0:
				shieldhit = true
	
	if playerhit:
		if shieldhit:
			query.collision_mask = Layers.solid
			var reflection = velocity.bounce(Game.player.forwards())
			var strength = Game.player.shield.bash_str + 0.2
			var player_hvelocity = Vector3(Game.player.velocity.x, 0.0, Game.player.velocity.z)
			#var lob_amount = -min(0.0, Game.player.forwards().dot(Game.player.velocity.normalized()))
			velocity = reflection * strength + player_hvelocity
			translation += velocity * t
		else:
			Game.player.set_locked(10)
			queue_free()
	else:
		queue_free()
