extends MeshInstance

# Collision
var query := PhysicsShapeQueryParameters.new()
var shape := SphereShape.new()

# Animation
onready var anim = $AnimationPlayer

# Material
var material:Material

# Properties
var velocity:Vector3

# Flags
var is_ready:bool = false

func _ready() -> void:
	# Duplicate material per bomb
	material = get_surface_material(0).duplicate()
	set_surface_material(0, material)
	
	# Set up physics query
	query.exclude = [Game.player]
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
	query.exclude = []
	anim.play("explode")
	set_physics_process(false)
	
func _animation_finished(anim_name:String) -> void:
	match(anim_name):
		"bomb_pull":
			is_ready = true
		"explode":
			queue_free()
