extends KinematicBody

var framecount:int = 0
var velocity := Vector3.ZERO

# Colors
var body_color_lit:Color
var body_color_dim:Color
var locked_color_lit := Color(1.0, 0.25, 0.25)
var locked_color_dim := Color(0.5, 0.125, 0.125)

# Target
var zl_target:int = 0

# Flags
var grounded:bool = true
var has_jump:bool = true
var jumping:bool = false
var targeting:bool = false
var slippery:bool = false

# Timers
var maxspeed_framecount:int = 0 # Track the # of consecutive frames the left joystick is fully pressed (for acceleration)
var jumphold_framecount:int = 0 # Track the # of consecutive frames jump is held for (variable jump height)
var lock_framecount:int = 0 # Amount of frames the player has no control. Used post respawn.
var aerial_framecount:int = 0 # Amount of frames the player has been in the air.
var shieldbash_framecount:int = 0 # The player has a certain amount of frames to initate a shield bash

# Child Nodes
onready var raycast = $RayCast
onready var shield = $Shield  # contains shield.active, a bool saying if shield is up or not
onready var material = $Body.get_surface_material(0)

func _ready() -> void:
	process_priority = 0 # Run this before camera
	
	# Save the initial color of the character
	body_color_lit = material.get_shader_param("color_lit")
	body_color_dim = material.get_shader_param("color_dim")
	
	# Set locked state
	set_locked(20)

func set_locked(framecount:int) -> void:
	lock_framecount = framecount
	if framecount > 0:
		material.set_shader_param("color_lit", locked_color_lit)
		material.set_shader_param("color_dim", locked_color_dim)
	else:
		material.set_shader_param("color_lit", body_color_lit)
		material.set_shader_param("color_dim", body_color_dim)

func set_grounded(state:bool) -> void:
	if grounded != state:
		# Transition to grounded:
		if state == true:
			jumphold_framecount = 0
			aerial_framecount = 0
			has_jump = true
	grounded = state

func set_target(state:bool) -> void:
	targeting = state
	if targeting:
		zl_target = TargetSystem.get_most_relevant_target()
		if zl_target == 0: Game.cam.resetting = true
	else:
		zl_target = 0

func _process(t) -> void:
	Game.debug.text.write('Frame: ' + str(framecount))
	Game.debug.text.write('Frame Time: ' + str(t))
	Game.debug.text.newline()

func _physics_process(t) -> void:
	framecount += 1
	
	# Add Gravity
	velocity.y += Game.GRAVITY * t
	
	# Prevent player movement if locked
	if lock_framecount > 0:
		lock_framecount -= 1
		velocity.x = lerp(velocity.x, 0.0, 0.15)
		velocity.z = lerp(velocity.z, 0.0, 0.15)
		if lock_framecount == 0:
			set_locked(0)
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
		
		# Movement
		var direction:Vector3 = find_movement_direction()
		var velocity_xz = Vector3(velocity.x, 0, velocity.z)
		var speed:float = 8.0 if not shield.active else 2.0
		var interpolate_amt:float = 0.15 if grounded else 0.015
		if slippery: speed *= 0.05
		
		# Targeted movement
		if targeting and not shield.active:
			var diff = direction.angle_to(forwards())
			if diff > PI * 0.5:
				diff = PI * 0.5
			speed -= (speed / 2.0) * (diff / (PI * 0.5))
		
		# Sprinting
		if grounded and not shield.active and not targeting:
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
			if shield.active: velocity.y /= 2.0
			if jumphold_framecount >= 10 or not Input.is_action_pressed("jump"):
				jumping = false
			else:
				jumphold_framecount += 1
		elif has_jump and Input.is_action_just_pressed('jump'):
			has_jump = false
			jumping = true
	
	# Apply physics
	var impact:float = velocity.length()
	velocity = move_and_slide(velocity, Vector3.UP)
	impact -= velocity.length()
	if impact > 10.0:
		set_locked(int(impact))
	
	var on_wall = is_on_wall()
	set_grounded(raycast.is_colliding())
	
	# Check for slippery surface
	slippery = false
	if not grounded:
		for i in range (get_slide_count()):
			if get_slide_collision(i).collider.collision_layer & Layers.slippery > 0:
				slippery = true
				has_jump = false
				break
	
	# If velocity is very small, make it 0
	if not slippery:
		if velocity.length_squared() < 0.0001: velocity = Vector3.ZERO

	# Player Rotation:
	if lock_framecount == 0: # Do not rotate while locked.
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
	
	# If player fell off the map, respawn
	if translation.y < -50:
		translation = Vector3.ZERO
		velocity = Vector3.ZERO
		rotation = Vector3.ZERO
		set_locked(20)
		Game.cam.resetting = true
	
	# Debug Text
	Game.debug.text.write('Position: ' + str(translation))
	Game.debug.text.write('Velocity: ' + str(velocity))
	Game.debug.text.write('Horizontal Velocity: ' + str(Vector3(velocity.x, 0, velocity.z).length()))
	Game.debug.text.write('Forward Direction: ' + str(forwards()))
	Game.debug.text.newline()
	Game.debug.text.write('Locked: ' + str(lock_framecount), 'green' if lock_framecount > 0 else 'red')
	Game.debug.text.write('Targeting: ' + str(targeting), 'green' if targeting else 'red')
	Game.debug.text.write('Grounded: ' + str(grounded), 'green' if grounded else 'red')
	Game.debug.text.write('On Wall: ' + str(on_wall), 'green' if on_wall else 'red')
	Game.debug.text.write('Has Jump: ' + str(has_jump), 'green' if has_jump else 'red')
	Game.debug.text.write('Jumping: ' + str(jumping), 'green' if jumping else 'red')
	Game.debug.text.write('Slippery: ' + str(slippery), 'green' if slippery else 'red')
	Game.debug.text.write('Shielding: ' + str(shield.active), 'green' if shield.active else 'red')
	Game.debug.text.newline()
	Game.debug.text.write('Holding Maxspeed: ' + str(maxspeed_framecount) + '/180')
	Game.debug.text.write('Jumphold Framecount: ' + str(jumphold_framecount) + '/10')
	Game.debug.text.write('Air Time: ' + str(aerial_framecount))
	Game.debug.text.write("Impact: " + str(impact))
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
	if shield.active: angle = clamp(angle, -PI/80.0, PI/80.0)  # Slow rotation while shielding
	else:             angle = clamp(angle, -PI/8.0,  PI/8.0)   # Fast rotation while not shielding
	
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
	
