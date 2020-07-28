extends KinematicBody

var framecount:int = 0
var frame_time:float = 1.0 / 60.0
var velocity := Vector3.ZERO

# Target List
var target_list:Dictionary = {}

# Flags
var grounded:bool = true
var has_jump:bool = true
var jumping:bool = false
var targeting:bool = false
var slippery:bool = false
var shielding:bool = false

# Timers
var maxspeed_framecount:int = 0 # Track the # of consecutive frames the left joystick is fully pressed (for acceleration)
var jumphold_framecount:int = 0 # Track the # of consecutive frames jump is held for (variable jump height)
var lock_framecount:int = 10 # Amount of frames the player has no control. Used post respawn.
var aerial_framecount:int = 0 # Amount of frames the player has been in the air.

# Child Nodes
onready var raycast = $"RayCast"
onready var shield = $"Shield"

func _ready() -> void:
	process_priority = 0 # Run this before camera

func set_shield(state:bool) -> void:
		shielding = state
		shield.visible = state
		if shielding:
			maxspeed_framecount = 0

func _physics_process(t) -> void:
	framecount += 1
		
	# If player fell off the map, respawn
	if translation.y < -50: 
		translation = Vector3.ZERO
		velocity = Vector3.ZERO
		lock_framecount = 10
		set_shield(false)
	
	# Manage Target List
	for area in target_list:
		var target = target_list[area]
		
		# Get target position
		var target_pos = area.global_transform.origin
		
		# Check if there is line of sight
		var space_state = get_world().direct_space_state
		var result = space_state.intersect_ray(translation, target_pos, [], Layers.solid | Layers.slippery)
		var blocked = false
		if result.size() > 0:
			blocked = true
		
		# Assign properties
		target.aabb = target.parent.get_aabb()
		target.pos = target_pos
		target.length = (target_pos - translation).length()
		target.blocked = blocked
		target.move_vector = -(translation - target_pos).normalized()
		
		# find primary target
		# and do stuff w/ that
	
	# Add Gravity
	var gravity:float = -20.0 # I will never understand why -9.8 feels super floaty when using 1.7m tall character
	velocity.y += gravity * frame_time
	
	# Prevent player movement if locked
	if lock_framecount > 0:
		lock_framecount -= 1
	else:
		# Check if targeting
		if Input.is_action_pressed("target"):
			targeting = true
		elif Game.cam.resetting == false:
			targeting = false
		
		# Check if shielding
		set_shield(Input.is_action_pressed("shield"))
		
		# Movement
		var direction:Vector3 = find_movement_direction()
		var velocity_xz = Vector3(velocity.x, 0, velocity.z)
		var speed:float = 8.0 if not shielding else 3.0
		var interpolate_amt:float = 0.15 # per frame
		if slippery: speed *= 0.05
		
		# Targeted movement
		if targeting and not shielding:
			maxspeed_framecount = 0
			var face_dir = Vector3.FORWARD.rotated(Vector3.UP, rotation.y)
			var diff = direction.angle_to(face_dir)
			if diff > PI * 0.5:
				diff = PI * 0.5
			speed -= (speed / 2.0) * (diff / (PI * 0.5))
		
		# Grounded movement
		if grounded:
			# Sprinting
			if direction.is_normalized(): 
				if maxspeed_framecount < 180: maxspeed_framecount += 1
				speed += 2.0 * (float(maxspeed_framecount) / 180.0)
			else:
				maxspeed_framecount = 0
		
		# Aerial movement
		else:
			maxspeed_framecount = 0
			# Remove Jump if too much time has passed
			if aerial_framecount == 4:
				has_jump = false
			aerial_framecount += 1
			interpolate_amt *= 0.1 # Much smaller interpolation value for air movement
			velocity_xz *= 0.999 # Aerial horizontal speed decay
		
		# Interpolate horizontal movement
		velocity_xz = velocity_xz.linear_interpolate(direction * speed, interpolate_amt)
		velocity.x = velocity_xz.x
		velocity.z = velocity_xz.z
		
		# Jumping
		if jumping:
			velocity.y = 7.0 - (float(jumphold_framecount) * 0.1)
			if shielding: velocity.y /= 2.0
			if jumphold_framecount >= 10 or not Input.is_action_pressed("jump"):
				jumping = false
			else:
				jumphold_framecount += 1
		elif has_jump and Input.is_action_just_pressed('jump'):
			has_jump = false
			jumping = true
	
	# Apply physics
	velocity = move_and_slide(velocity, Vector3.UP)
	
	# Check for slippery surface
	slippery = false
	if not raycast.is_colliding():
		for i in range (get_slide_count()):
			if get_slide_collision(i).collider.collision_layer == Layers.slippery:
				slippery = true
				grounded = false
				has_jump = false
	
	# Check for ground<->air transition
	if not slippery and grounded != is_on_floor():
		grounded = raycast.is_colliding() or is_on_floor() # Set grounded flag
		if grounded:
			# Landing transition
			jumphold_framecount = 0
			aerial_framecount = 0
			has_jump = true
		else:
			# Air transition
			pass
	
	# If velocity is very small, make it 0
	if velocity.length_squared() < 0.0001:
		velocity = Vector3.ZERO
	
	# Player rotation: look towards movement dir
	if not targeting and (grounded or slippery):
		var h_velocity := Vector2(velocity.x, velocity.z).normalized() # Get horizontal velocity as a normalized vec2
		if h_velocity != Vector2.ZERO: # If the horizontal velocity is zero, don't rotate the player
			var forward:Vector3 = forwards() # Get current facing direction
			var angle = -Vector2(forward.x, forward.z).angle_to(h_velocity) # Find angle from face dir to velocity dir
			if shielding: angle = clamp(angle, -PI/80.0, PI/80.0) # clamp it
			else:         angle = clamp(angle, -PI/8.0, PI/8.0)
			angle *= clamp(Vector3(velocity.x, 0, velocity.z).length_squared(), 0.0, 1.0) # very slow walk speed means slow rotation
			var look_target:Vector3 = forward.rotated(Vector3.UP, angle) # use clamped angle to find new facing direction
			look_at(look_target + translation, Vector3.UP) # rotate
				
	# Debug Text
	Game.debug.text.write('Frame: ' + str(framecount))
	Game.debug.text.write('Frame Time: ' + str(t))
	Game.debug.text.newline()
	Game.debug.text.write('Position: ' + str(translation))
	Game.debug.text.write('Velocity: ' + str(velocity))
	Game.debug.text.write('Horizontal Velocity: ' + str(Vector3(velocity.x, 0, velocity.z).length()))
	Game.debug.text.newline()
	Game.debug.text.write('Targeting: ' + str(targeting), 'green' if targeting else 'red')
	Game.debug.text.write('Grounded: ' + str(grounded), 'green' if grounded else 'red')
	Game.debug.text.write('Has Jump: ' + str(has_jump), 'green' if has_jump else 'red')
	Game.debug.text.write('Jumping: ' + str(jumping), 'green' if jumping else 'red')
	Game.debug.text.write('Slippery: ' + str(slippery), 'green' if slippery else 'red')
	Game.debug.text.write('Shielding: ' + str(shielding), 'green' if shielding else 'red')
	Game.debug.text.newline()
	Game.debug.text.write('Holding Maxspeed: ' + str(maxspeed_framecount) + '/180')
	Game.debug.text.write('Jumphold Framecount: ' + str(jumphold_framecount) + '/10')
	Game.debug.text.write('Air Time: ' + str(aerial_framecount))
	Game.debug.text.newline()
	Game.debug.text.write('Target list:')
	for area in target_list:
		var target = target_list[area]
		Game.debug.text.write(target.name + ' @ ' + str(target.pos), 'blue')
	Game.debug.text.newline()
	
	# Debug Draw
	Game.debug.draw.begin(Mesh.PRIMITIVE_LINES)
	Game.debug.draw.add_vertex(translation + Vector3.UP)
	Game.debug.draw.add_vertex(translation + Vector3.UP + forwards())
	Game.debug.draw.add_vertex(translation + Vector3.UP)
	Game.debug.draw.add_vertex(translation + Vector3(velocity.x, 0, velocity.z).normalized() + Vector3.UP)
	Game.debug.draw.end()

func forwards() -> Vector3:
	return -transform.basis.z.normalized()

func find_movement_direction() -> Vector3:
	var pushdir:Vector2 = Game.get_stick_input("left")
	var camdir:Vector3 = Game.cam.get_global_transform().basis.z
	camdir.y = 0.0
	camdir = camdir.normalized()
	return (camdir * pushdir.y) + (camdir.rotated(Vector3.UP, PI/2) * pushdir.x)
	
func _target_acquired(area: Area) -> void:
	var parent = area.get_parent()	
	# More properties assigned and updated when managing the target list elsewhere
	# These ones are static so I can assign them here and never again.
	target_list[area] = {
		"parent": parent,
		"name": parent.name
	}

func _target_lost(area: Area) -> void:
	target_list.erase(area)
