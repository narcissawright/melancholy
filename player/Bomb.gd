extends MeshInstance

# Collision
var query := PhysicsShapeQueryParameters.new()
var shape := SphereShape.new()

# Animation
onready var anim = $AnimationPlayer

# Properties
var velocity:Vector3

func _ready() -> void:
	# Duplicate material per bomb
	set_surface_material(0, get_surface_material(0).duplicate())
	
	# Set up physics query
	query.collision_mask = Layers.solid | Layers.actor
	shape.radius = 0.3
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
	scale = Vector3(10, 10, 10)
	get_surface_material(0).set_shader_param("damaged", true)
	set_physics_process(false)
	
	# need to make some kind of animation here, and when its done, queue free.
	
	#queue_free()
