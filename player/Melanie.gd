extends KinematicBody

var framecount:int = 0
var frame_time:float = 1.0 / 60.0
var velocity := Vector3.ZERO
var position setget , _get_position # Uses the Position3D node. Camera points at this, enemies attack this point.
var look_target:Vector3 # used for Rotation

# Target
var zl_target:int = 0

# Flags
var grounded:bool = true
var has_jump:bool = true
var jumping:bool = false
var targeting:bool = false

# Timers
var maxspeed_framecount:int = 0 # Track the # of consecutive frames the left joystick is fully pressed (for acceleration)
var jumphold_framecount:int = 0 # Track the # of consecutive frames jump is held for (variable jump height)
var lock_framecount:int = 0 # Amount of frames the player has no control. Used post respawn.
var aerial_framecount:int = 0 # Amount of frames the player has been in the air.
var shieldbash_framecount:int = 0 # The player has a certain amount of frames to initate a shield bash

# Subweapons
var current_subweapon:String = "bomb"
var jewels:int = 99
var holding_bomb:bool = false

# Child Nodes
onready var position3d = $Position3D
onready var raycast = $RayCast
onready var shield = $ShieldAnim  # contains shield.active, a bool saying if shield is up or not
onready var material = $Body.get_surface_material(0)
onready var bombspawner = $BombSpawner

func _ready() -> void:
	process_priority = 0 # Run this before camera
	
	# Set locked state
	set_locked(20)

func _process(t) -> void:
	Debug.text.write('Frame: ' + str(framecount))
	Debug.text.write('Frame Time: ' + str(t))
	Debug.text.newline()

func _physics_process(t) -> void:
	framecount += 1
	update_player_state()
	var collision:KinematicCollision = move_and_collide(velocity * frame_time) # Apply Physics
	set_grounded(raycast.is_colliding()) # Check if grounded
	handle_collision(collision) # Redirect velocity, check landing impact, etc
	if velocity.length_squared() < 0.0001: velocity = Vector3.ZERO # If velocity is very small, make it 0
	handle_player_rotation() # Make player face the correct direction
	respawn_check() # Check if player fell below the map
	debug() # Write debug info onscreen

# For external nodes targeting the player.
func _get_position() -> Vector3:
	return position3d.global_transform.origin

func set_locked(count:int) -> void:
	lock_framecount = count
	if count > 0: 
		material.set_shader_param("damaged", true)
	else:
		material.set_shader_param("damaged", false)

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
		if zl_target == 0: 
			Game.cam.resetting = true
			# align with wall if relevant
			var from = Game.player.position
			var to =   Game.player.position + forwards() * 0.25
			var result = get_world().direct_space_state.intersect_ray(from, to, [], Layers.solid)
			if result.size() > 0:
				look_at(translation - result.normal, Vector3.UP)
	else:
		zl_target = 0

func update_player_state() -> void:
	
	var movement_direction = Vector3.ZERO # includes magnitude.
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	var interpolate_amt:float = 0.15 if grounded else 0.015
	
	if lock_framecount > 0:
		lock_framecount -= 1
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
	
		# Left Stick Movement
		var direction:Vector3 = find_movement_direction()
		look_target = look_target.linear_interpolate(direction, 0.15) # Used for player rotation later
		var speed:float = 8.0
		if shield.active: speed = 2.0
		
		# Targeted movement
		if targeting and not shield.active:
			# Forward movement is not impeded much, while sideways or backwards is slower
			var diff = direction.angle_to(forwards())
			if diff > PI * 0.5:
				diff = PI * 0.5
			speed -= (speed / 2.0) * (diff / (PI * 0.5))
		
		# Sprinting
		if grounded and not shield.active and not targeting:
			if direction.is_normalized(): # If joystick fully pressed
				if maxspeed_framecount < 180: maxspeed_framecount += 1 # Build speed over three seconds
				speed += 2.0 * (float(maxspeed_framecount) / 180.0)
			else: maxspeed_framecount = 0
		else: maxspeed_framecount = 0
		
		# Aerial movement
		if not grounded:
			if aerial_framecount == 5: has_jump = false # Remove Jump if too much time has passed
			aerial_framecount += 1
			horizontal_velocity *= 0.999 # Aerial horizontal speed decay
		
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
		
		# Subweapons
		if not shield.active:
			if Input.is_action_just_pressed("subweapon"):
				match(current_subweapon):
					"bomb":
						if holding_bomb: # If you are already holding the bomb, throw it.
							if bombspawner.can_throw_bomb():
								# I want to add a buffer system here so that if you double tap it will throw asap.
								# even if the pull anim is not finished.
								
								
								bombspawner.throw_bomb(forwards() * 10.0 + Vector3.UP * 5.0)
								holding_bomb = false
						elif bombspawner.can_spawn_bomb(): # If a bomb can be spawned, do so.
							bombspawner.spawn_bomb()
							holding_bomb = true
			
		movement_direction = direction * speed
	
	# Interpolate horizontal movement
	horizontal_velocity = horizontal_velocity.linear_interpolate(movement_direction, interpolate_amt)
	velocity = Vector3(horizontal_velocity.x, velocity.y, horizontal_velocity.z)
	velocity.y += Game.GRAVITY * frame_time

func forwards() -> Vector3:
	return -transform.basis.z

func find_movement_direction() -> Vector3:
	var pushdir:Vector2 = Game.get_stick_input("left")
	var camdir:Vector3 = Game.cam.get_global_transform().basis.z
	camdir.y = 0.0
	camdir = camdir.normalized()
	return (camdir * pushdir.y) + (camdir.rotated(Vector3.UP, PI/2) * pushdir.x)

func handle_collision(collision:KinematicCollision) -> void:
	# If a collision has occured:
	if collision:
		var impact:float = velocity.length()
		velocity = velocity.slide(collision.normal)
		impact -= velocity.length()
		if impact > 10.0:
			set_locked(int(impact))

func handle_player_rotation() -> void:
	if lock_framecount == 0:
		
		# While grounded -- look towards movement direction
		if not targeting and grounded:
			var look_target_2d = Vector2(look_target.x, look_target.z).normalized()
			if not look_target_2d.is_equal_approx(Vector2.ZERO): # If not moving, don't rotate
				rotate_towards(look_target_2d)

		# While targeting -- look towards target
		elif targeting and zl_target != 0:
			var look_target_2d := Vector2(translation.x, translation.z)
			look_target_2d -= Vector2(TargetSystem.list[zl_target].pos.x, TargetSystem.list[zl_target].pos.z)
			look_target_2d = -look_target_2d.normalized()
			rotate_towards(look_target_2d)

func rotate_towards(look_target_2d:Vector2) -> void:
	# find the amount of radians needed to face target direction
	var angle = -Vector2(forwards().x, forwards().z).angle_to(look_target_2d)
	
	# Takes in a rotation amount in radians, and clamps it to the maximum allowed rotation amount
	if shield.active: angle = clamp(angle, -PI/80.0, PI/80.0)  # Slow rotation while shielding
	else:             angle = clamp(angle, -PI/8.0,  PI/8.0)   # Fast rotation while not shielding
	
	# If you are not targeting, have the rotation amount be very small when moving slowly
	if not targeting: angle *= clamp(Vector3(velocity.x, 0, velocity.z).length_squared(), 0.0, 1.0)
	
	# If angle is close to 0, don't bother
	if not is_equal_approx(angle, 0.0):
		var lookdir:Vector3 = forwards().rotated(Vector3.UP, angle)
		look_at(lookdir + translation, Vector3.UP) # rotate

func respawn_check() -> void:
	# If player fell off the map, respawn
	if translation.y < -50:
		translation = Vector3.ZERO
		velocity = Vector3.ZERO
		rotation = Vector3.ZERO
		set_locked(20)
		Game.cam.resetting = true

func hit(collision:Dictionary) -> String:
	if collision.shape > 0: # hit shield
		return "bounce"
	else:
		set_locked(10)
		return "die"

func debug() -> void:
	# Debug Text

	Debug.text.write('Subweapon: ' + str(current_subweapon))
	Debug.text.write('Jewels: ' + str(jewels))
	Debug.text.write('can_spawn_bomb()', 'green' if bombspawner.can_spawn_bomb() else 'red')
	Debug.text.newline()
	Debug.text.write('Vertical Velocity: ' + str(velocity.y))
	Debug.text.write('Horizontal Velocity: ' + str(Vector3(velocity.x, 0, velocity.z).length()))
#	Debug.text.write('Forward Direction: ' + str(forwards()))
	Debug.text.newline()
	Debug.text.write('Locked: ' + str(lock_framecount), 'green' if lock_framecount > 0 else 'red')
	Debug.text.write('Targeting: ' + str(targeting), 'green' if targeting else 'red')
	Debug.text.write('Grounded: ' + str(grounded), 'green' if grounded else 'red')
	Debug.text.write('Has Jump: ' + str(has_jump), 'green' if has_jump else 'red')
	Debug.text.write('Jumping: ' + str(jumping), 'green' if jumping else 'red')
	Debug.text.newline()
	Debug.text.write('Shielding: ' + str(shield.active), 'green' if shield.active else 'red')
	Debug.text.write('Bashing: ' + str(shield.bash_str), 'green' if shield.bash_str > 0.0 else 'red')
	Debug.text.newline()
	Debug.text.write('Sprinting: ' + str(maxspeed_framecount) + '/180')
#	Debug.text.write('Jumphold Framecount: ' + str(jumphold_framecount) + '/10')
	Debug.text.write('Air Time: ' + str(aerial_framecount))
	Debug.text.newline()
	if zl_target == 0:
		Debug.text.write("ZL Target: ")
	else:
		Debug.text.write("ZL Target: " + TargetSystem.list[zl_target].name, 'blue')
	Debug.text.newline()
	
	# Debug Draw
	Debug.draw.begin(Mesh.PRIMITIVE_LINES)
	Debug.draw.add_vertex(Game.player.position)
	Debug.draw.add_vertex(Game.player.position + forwards())
	Debug.draw.add_vertex(Game.player.position)
	Debug.draw.add_vertex(Game.player.position + Vector3(velocity.x, 0, velocity.z).normalized())
	Debug.draw.end()

