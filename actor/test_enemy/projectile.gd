extends MeshInstance 

# Properties
var velocity:Vector3 # set by creator
var lifespan = 5.0
var projectile_owner # node

# Collision
var query := PhysicsShapeQueryParameters.new()
var shape := SphereShape.new()

func _ready() -> void:
	query.exclude = [projectile_owner]
	query.transform = global_transform
	query.collision_mask = Layers.solid | Layers.actor
	shape.radius = 0.1
	query.set_shape(shape)

func _physics_process(t: float) -> void:
	var move_vec:Vector3 = velocity * t
	
	if not move_vec.is_equal_approx(Vector3.ZERO): # Avoid calling cast_motion with empty vec3
		query.transform = global_transform
		var space_state = get_world().direct_space_state
		var result = space_state.cast_motion(query, move_vec)
		translation += move_vec * result[1]
		if result[1] != 1: # if cannot move the full distance
			hit(space_state, t)
	
	lifespan -= t
	if lifespan <= 0: die()
	
	velocity.y += (Level.GRAVITY * 0.5 ) * t
	
func die() -> void:
	queue_free()
	
func hit(space_state, t):
	query.transform = global_transform
	var collision:Dictionary = space_state.intersect_shape(query, 1)[0]
	var collision_response = "die"
	
	if collision.collider.collision_layer & Layers.actor > 0:
		var actor = collision.collider
		if actor.has_method("hit"):
			collision_response = actor.hit(collision)
	
	match collision_response:
		"die": 
			die()
		"bounce":
			query.exclude = [Player]
			var reflection = velocity.bounce(Player.forward)
			var strength = Player.shield.bash_str + 0.2
			var player_hvelocity = Vector3(Player.velocity.x, 0.0, Player.velocity.z)
			#var lob_amount = -min(0.0, Player.forwards().dot(Game.player.velocity.normalized()))
			velocity = reflection * strength + player_hvelocity
			translation += velocity * t
	
