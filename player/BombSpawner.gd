extends Position3D
onready var bomb = $'Bomb'

# Collision
var query := PhysicsShapeQueryParameters.new()
var shape := SphereShape.new()
var move_vec:Vector3

func _ready() -> void:
	bomb.hide()
	query.exclude = [Game.player]
	query.collision_mask = Layers.solid | Layers.actor
	shape.radius = 0.3
	query.set_shape(shape)

func can_spawn_bomb() -> bool:
	query.transform = global_transform.translated(Vector3.DOWN)
	var space_state = get_world().direct_space_state
	var result = space_state.cast_motion(query, Vector3.UP)
	if result[1] == 1:
		return true
	return false

func spawn_bomb() -> void:
	# Check if there is a ceiling or something in the way
	
	
	
	
	bomb.scale = 0.01 # maybe animationplayer again?
	# should I use multiple animationplayers?
	bomb.show()
