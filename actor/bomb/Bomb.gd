extends Position3D

""" 
Known exploits:
	- Bomb Jump (intentional)
	- Double Bomb Jump (the timing is tight but it's a half decent mechanic)
	- Double Bomb Slide (requires taking damage.. seems acceptable)
	
To Be Improved:
	- particles, lighting, sfx.
"""

# Collision
var query := PhysicsShapeQueryParameters.new()
var shape := SphereShape.new()

# Animation
onready var anim = $AnimationPlayer

# Meshes
onready var bomb_mesh = $BombModel
onready var explosion_mesh = $Explosion

# Explosion Data
var explosion_list:Array # Keep track of what has been hit already.

# Properties
var velocity:Vector3
var throw_spin:Vector3 # added to rotation each frame while thrown or dropped. purely visual.

# Flags
var is_ready:bool = false
var exploding:bool = false

func _ready() -> void:
	
	# Duplicate material per bomb
	var material = bomb_mesh.get_surface_material(0).duplicate()
	bomb_mesh.set_surface_material(0, material)
	material = explosion_mesh.get_surface_material(0).duplicate()
	explosion_mesh.set_surface_material(0, material)
	
	# Set up physics query
	query.exclude = [Player.kinematicbody]
	query.collision_mask = Layers.solid | Layers.actor
	shape.radius = 0.2
	query.set_shape(shape)
	set_physics_process(false)
	
	# Play pull animation
	anim.play("bomb_pull")

func throw(v:Vector3) -> void:
	velocity = v
	if v == Vector3.ZERO:
		throw_spin = Vector3(randf(), randf(), randf()) * 0.02
	else:
		throw_spin = Vector3(randf(), randf(), randf()) * 0.05
	set_physics_process(true)

# Apply gravity, use shapecasting to determine collisions.
func _physics_process(t:float) -> void:
	rotation += throw_spin
	velocity.y += Level.GRAVITY * t
	var step = velocity * t
	query.transform = global_transform
	if not step.is_equal_approx(Vector3.ZERO): # If step is zero distance, cast_motion returns empty array.
		var space_state = get_world().direct_space_state
		var result = space_state.cast_motion(query, step)
		translation += step * result[1]
		if result[1] != 1:
			explode()

# Kaboom!
func explode() -> void:
	if Player.bombspawner.current_bomb == self:
		reparent_to_game_world()
	exploding = true
	anim.play("explode")
	set_physics_process(false)

# Detach bomb from player.
func reparent_to_game_world() -> void:
	Player.bombspawner.holding = false
	call_deferred('reparent_deferred')

# Don't call this directly, use reparent_to_game_world() instead.
func reparent_deferred() -> void:
	var current_transform = global_transform
	get_parent().remove_child(self)
	Level.Projectiles.add_child(self)
	global_transform = current_transform

# Signal from AnimationPlayer
func _animation_finished(anim_name:String) -> void:
	match(anim_name):
		"bomb_pull":
			is_ready = true
			anim.play("pulse")
		"pulse":
			explode()
		"explode":
			queue_free()

# Called when this bomb's explosion hits an actor
func _on_ExplosionHit(body: Node) -> void:
	if not explosion_list.has(body):
		explosion_list.append(body) # Prevent calling this twice
		if body.has_method("hit_by_explosion"):
			body.hit_by_explosion(global_transform.origin)

# Called when this bomb touches an external explosion
func _on_ExplosionDetected(_area: Area) -> void:
	explode()
