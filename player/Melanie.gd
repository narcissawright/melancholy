extends KinematicBody

var framecount:int = 0
var velocity := Vector3.ZERO

# Target
var zl_target:int = 0

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
onready var raycast = $RayCast
onready var shield = $Shield

func _ready() -> void:
	process_priority = 0 # Run this before camera

func set_target(state:bool) -> void:
	targeting = state
	if targeting:
		zl_target = TargetSystem.get_most_relevant_target()
		if zl_target == 0: Game.cam.resetting = true
	else:
		zl_target = 0

func set_shield(state:bool) -> void:
	shielding = state
	shield.visible = state

func _physics_process(t) -> void:
	framecount += 1
		
	# If player fell off the map, respawn
	if translation.y < -50:
		translation = Vector3.ZERO
		velocity = Vector3.ZERO
		lock_framecount = 10
		set_shield(false)
		
	# Add Gravity
	var gravity:float = -20.0 # I will never understand why -9.8 feels super floaty when using 1.7m tall character
	velocity.y += gravity * t
	
	# Prevent player movement if locked
	if lock_framecount > 0:
		lock_framecount -= 1
	else:
		
		# Begin ZL Targeting:
		if not targeting and Input.is_action_just_pressed("target"):
			set_target(true)
		
		# Check if no longer targeting:
		if Input.is_action_pressed("target"):
			if not TargetSystem.target_is_valid(zl_target):
				# Target broken from distance or lost line of sight
				set_target(false)
		elif Game.cam.resetting == false:
			# If you are not holding the button, and the cam reset has finished, 
			# you are no longer targeting anything
			set_target(false)
		
		# Check if shielding
		set_shield(Input.is_action_pressed("shield"))
		
		# Movement
		var direction:Vector3 = find_movement_direction()
		var velocity_xz = Vector3(velocity.x, 0, velocity.z)
		var speed:float = 8.0 if not shielding else 3.0
		var interpolate_amt:float = 0.15 if grounded else 0.015
		if slippery: speed *= 0.05
		
		# Targeted movement
		if targeting and not shielding:
			var diff = direction.angle_to(forwards())
			if diff > PI * 0.5:
				diff = PI * 0.5
			speed -= (speed / 2.0) * (diff / (PI * 0.5))
		
		# Sprinting
		if grounded and not shielding and not targeting:
			if direction.is_normalized(): # If joystick fully pressed
				if maxspeed_framecount < 180: maxspeed_framecount += 1
				speed += 2.0 * (float(maxspeed_framecount) / 180.0) # Bonus speed
			else: maxspeed_framecount = 0
		else: maxspeed_framecount = 0
		
		# Aerial movement
		if not grounded:
			if aerial_framecount == 5: has_jump = false # Remove Jump if too much time has passed
			aerial_framecount += 1
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
				break
	
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
	if velocity.length_squared() < 0.0001: velocity = Vector3.ZERO
	
	# Player Rotation:
	# While not targeting -- look towards movement direction
	if not targeting and (grounded or slippery):
		var look_target_2d := Vector2(velocity.x, velocity.z).normalized() # horizontal velocity as a normalized vec2
		if not look_target_2d.is_equal_approx(Vector2.ZERO): # If the horizontal velocity is zero, don't rotate
			rotate_player(look_target_2d)
	# While targeting -- look towards target
	elif targeting and (grounded or slippery) and zl_target != 0:
		var look_target_2d := Vector2(translation.x, translation.z)
		look_target_2d -= Vector2(TargetSystem.list[zl_target].pos.x, TargetSystem.list[zl_target].pos.z)
		look_target_2d = -look_target_2d.normalized()
		rotate_player(look_target_2d)
	
	# Debug Text
	Game.debug.text.write('Frame: ' + str(framecount))
	Game.debug.text.write('Frame Time: ' + str(t))
	Game.debug.text.newline()
	Game.debug.text.write('Position: ' + str(translation))
	Game.debug.text.write('Velocity: ' + str(velocity))
	Game.debug.text.write('Horizontal Velocity: ' + str(Vector3(velocity.x, 0, velocity.z).length()))
	Game.debug.text.write('Forward Direction: ' + str(forwards()))
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
	if zl_target == 0:
		Game.debug.text.write("ZL Target: ", 'red')
	else:
		Game.debug.text.write("ZL Target: " + TargetSystem.list[zl_target].name, 'green')
	Game.debug.text.newline()
	
	# Debug Draw
	Game.debug.draw.begin(Mesh.PRIMITIVE_LINES)
	Game.debug.draw.add_vertex(translation + Vector3.UP)
	Game.debug.draw.add_vertex(translation + Vector3.UP + forwards())
	Game.debug.draw.add_vertex(translation + Vector3.UP)
	Game.debug.draw.add_vertex(translation + Vector3(velocity.x, 0, velocity.z).normalized() + Vector3.UP)
	Game.debug.draw.end()

func rotate_player(look_target_2d:Vector2) -> void:
	# find the amount of radians needed to face target direction
	var angle = -Vector2(forwards().x, forwards().z).angle_to(look_target_2d)
	
	# Takes in a rotation amount in radians, and clamps it to the maximum allowed rotation amount
	if shielding: angle = clamp(angle, -PI/80.0, PI/80.0)  # Slow rotation while shielding
	else:         angle = clamp(angle, -PI/8.0,  PI/8.0)   # Fast rotation while not shielding
	
	# If you are not targeting, have the rotation amount be very small when moving slowly
	if not targeting: angle *= clamp(Vector3(velocity.x, 0, velocity.z).length_squared(), 0.0, 1.0)
	
	# If angle is close to 0, don't bother
	if not is_equal_approx(angle, 0.0):
		var look_target:Vector3 = forwards().rotated(Vector3.UP, angle)
		look_at(look_target + translation, Vector3.UP) # rotate

func forwards() -> Vector3:
	return -transform.basis.z

func find_movement_direction() -> Vector3:
	var pushdir:Vector2 = Game.get_stick_input("left")
	var camdir:Vector3 = Game.cam.get_global_transform().basis.z
	camdir.y = 0.0
	camdir = camdir.normalized()
	return (camdir * pushdir.y) + (camdir.rotated(Vector3.UP, PI/2) * pushdir.x)
	
