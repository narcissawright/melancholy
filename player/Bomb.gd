extends Position3D

# Collision
var query := PhysicsShapeQueryParameters.new()
var shape := SphereShape.new()

# Animation
onready var anim = $AnimationPlayer

# Material
onready var meshinstance = $MeshInstance
var material:Material

# Explosion
onready var explosion = $ExplosionArea
var explosion_list:Array # Keep track of what has been hit already.

# Properties
var velocity:Vector3

# Flags
var is_ready:bool = false

func _ready() -> void:
	# Duplicate material per bomb
	material = meshinstance.get_surface_material(0).duplicate()
	meshinstance.set_surface_material(0, material)
	
	# Set up physics query
	query.exclude = [Game.player]
	query.collision_mask = Layers.solid | Layers.actor
	shape.radius = 0.2
	query.set_shape(shape)
	set_physics_process(false)
	
	# Play pull animation
	anim.play("bomb_pull")
	
func throw(v:Vector3) -> void:
	velocity = v
	set_physics_process(true)

func _physics_process(t:float) -> void:
	velocity.y += Game.GRAVITY * t
	var step = velocity * t
	query.transform = global_transform
	if not step.is_equal_approx(Vector3.ZERO): # If step is zero distance, cast_motion returns empty array.
		var space_state = get_world().direct_space_state
		var result = space_state.cast_motion(query, step)
		translation += step * result[1]
		if result[1] != 1:
			explode()

func explode() -> void:
	anim.play("explode")
	set_physics_process(false)
	
#	query.exclude = [] # Player not immune to explosion
#	query.transform = global_transform # Update position
#	query.collision_mask = Layers.actor # Only check for actors
#	shape.radius = 2.0 # 10x scale, matches visual
#
#	var space_state = get_world().direct_space_state
#	var results = space_state.intersect_shape(query)
#	for i in range(results.size()):
#		var actor = results[i].collider
#		if actor.has_method("hit"):
#			actor.hit(results[i])
	
func _animation_finished(anim_name:String) -> void:
	match(anim_name):
		"bomb_pull":
			is_ready = true
		"explode":
			queue_free()

func _on_ExplosionHit(body: Node) -> void:
	if not explosion_list.has(body):
		explosion_list.append(body) # Prevent calling this twice
		if body.has_method("hit_by_explosion"):
			body.hit_by_explosion(global_transform.origin)
		
