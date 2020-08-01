extends KinematicBody

# Time
var framecount:int = 0
var frame_time:float = 1.0 / 60.0

# Locked state - player movement will not happen if locked.
var locked:bool = true
onready var lock_timer = $Timers/Locked

# Health
var hp:float = 200.0

# Grounded State
var grounded:bool = true
onready var raycast = $RayCast # Determines if the player is grounded or not

# Movement
var velocity := Vector3.ZERO
var sprint_count:int = 0 # Track the # of consecutive frames the left joystick is fully pressed (for acceleration)

# Rotation
var look_target:Vector3 # used for Rotation

# Targeting
var targeting:bool = false
var zl_target:int = 0

# Jumping
var has_jump:bool = true
var jumping:bool = false
var jumphold_framecount:int = 0 # Track the # of consecutive frames jump is held for (variable jump height)
onready var air_transition_timer = $Timers/AirTransition # Used to give jumps leniency when falling off of a ledge

# Shield
onready var shield = $ShieldAnim  # contains shield.active, a bool saying if shield is up or not

# Subweapons
var current_subweapon:String = "bomb"
var jewels:int = 99 # Subweapon ammo
onready var bombspawner = $BombSpawner

# Material
onready var material = $Body.get_surface_material(0)

# Position3D
onready var position3d = $Position3D # Camera points at this, enemies attack this point.
var position:Vector3 setget , _get_position  # Gets Position3D global_transform.origin

func _ready() -> void:
	process_priority = 0 # Run this before camera
	set_locked(20) # Set locked state

# For external nodes targeting the player.
func _get_position() -> Vector3:
	return position3d.global_transform.origin

func forwards() -> Vector3:
	return -transform.basis.z

func _physics_process(_t) -> void:
	framecount += 1
	update_target_state() # ZL Targeting
	update_horizontal_velocity() # General movement
	update_vertical_velocity() # Jumping and gravity
	
	var collision:KinematicCollision = move_and_collide(velocity * frame_time) # Apply Physics
	
	set_grounded(raycast.is_colliding()) # Check if grounded
	handle_collision(collision) # Redirect velocity, check landing impact, etc
	if velocity.length_squared() < 0.0001: velocity = Vector3.ZERO # If velocity is very small, make it 0
	handle_player_rotation() # Make player face the correct direction
	if not locked: update_subweapon_state() # performed AFTER move_and_collide to correctly place projectiles.
	respawn_check() # Check if player fell below the map
	debug() # Write debug info onscreen

######  ####   #####    #####  ######  ######
  ##   ##  ##  ##  ##  ##      ##        ##
  ##   ######  #####   ## ###  #####     ##
  ##   ##  ##  ##  ##  ##  ##  ##        ##
  ##   ##  ##  ##  ##   ####   ######    ##

func update_target_state() -> void:
	# Begin ZL Targeting:
	if not targeting and Input.is_action_just_pressed("target"):
		targeting = true
		zl_target = TargetSystem.get_most_relevant_target()
		if zl_target == 0: 
			Game.cam.resetting = true
			# align with wall if relevant
			var from = Game.player.position
			var to =   Game.player.position + forwards() * 0.25
			var result = get_world().direct_space_state.intersect_ray(from, to, [], Layers.solid)
			if result.size() > 0:
				look_at(translation - result.normal, Vector3.UP)
	
	# Check if no longer targeting:
	if Input.is_action_pressed("target"):
		if not TargetSystem.target_is_valid(zl_target):
			# Target broken from distance or lost line of sight
			targeting = false
			zl_target = 0
	elif Game.cam.resetting == false:
		targeting = false
		zl_target = 0

##  ##        ##  ##  #####  ##     ####    ####  ##  ######  ##  ##
##  ##        ##  ##  ##     ##    ##  ##  ##     ##    ##    ##  ##
######  ####  ##  ##  ####   ##    ##  ##  ##     ##    ##     ####
##  ##         ####   ##     ##    ##  ##  ##     ##    ##      ##
##  ##          ##    #####  #####  ####    ####  ##    ##      ##

func update_horizontal_velocity() -> void:
	var move_vec = Vector3.ZERO # includes magnitude.
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)
	var interpolate_amt:float = 0.15
	
	# Aerial movement
	if not grounded:
		interpolate_amt = 0.015
		horizontal_velocity *= 0.999
	
	if not locked:
		# Left Stick Movement
		var direction:Vector3 = find_movement_direction()
		look_target = look_target.linear_interpolate(direction, 0.15) # Used for player rotation later
		
		var speed:float = 8.0
		if shield.active: speed = 4.0
		
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
				if sprint_count < 180: sprint_count += 1 # Build speed over three seconds
				speed += 2.0 * (float(sprint_count) / 180.0)
			else: sprint_count = 0
		else: sprint_count = 0
		
		move_vec = direction * speed
	
	# Interpolate horizontal movement
	horizontal_velocity = horizontal_velocity.linear_interpolate(move_vec, interpolate_amt)
	velocity = Vector3(horizontal_velocity.x, velocity.y, horizontal_velocity.z)

func find_movement_direction() -> Vector3:
	var pushdir:Vector2 = Game.get_stick_input("left")
	var camdir:Vector3 = Game.cam.get_global_transform().basis.z
	camdir.y = 0.0
	camdir = camdir.normalized()
	return (camdir * pushdir.y) + (camdir.rotated(Vector3.UP, PI/2) * pushdir.x)

##  ##        ##  ##  #####  ##     ####    ####  ##  ######  ##  ##
##  ##        ##  ##  ##     ##    ##  ##  ##     ##    ##    ##  ##
##  ##  ####  ##  ##  ####   ##    ##  ##  ##     ##    ##     ####
 ####          ####   ##     ##    ##  ##  ##     ##    ##      ##
  ##            ##    #####  #####  ####    ####  ##    ##      ##

func update_vertical_velocity() -> void:
	# Apply Gravity
	velocity.y += Game.GRAVITY * frame_time
	
	"""
	I feel like my jump code is very jank and I wish to change it at some point.
	"""
	
	# Check for jumping
	if not locked:
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

##     ####    ####  ##  ##  ######  #####
##    ##  ##  ##     ## ##   ##      ##  ##
##    ##  ##  ##     ####    #####   ##  ##
##    ##  ##  ##     ## ##   ##      ##  ##
#####  ####    ####  ##  ##  ######  #####

# Locked State:
func set_locked(count:int) -> void:
	if count > 0: 
		# Set Flags
		locked = true
		jumping = false
		sprint_count = 0
		# Set Material
		material.set_shader_param("locked", true)
		# Set Timer
		lock_timer.wait_time = count * frame_time
		lock_timer.start()
	else:
		unlock()

# Unlock
func _on_Locked_timeout() -> void:
	unlock()
func unlock() -> void:
	locked = false
	material.set_shader_param("locked", false)
	material.set_shader_param("damaged", false)

 #####  #####    ####   ##  ##  ##  ##  #####   ######  #####
##      ##  ##  ##  ##  ##  ##  ### ##  ##  ##  ##      ##  ##
## ###  #####   ##  ##  ##  ##  ######  ##  ##  #####   ##  ##
##  ##  ##  ##  ##  ##  ##  ##  ## ###  ##  ##  ##      ##  ##
 ####   ##  ##   ####    ####   ##  ##  #####   ######  #####

# Grounded State:
func set_grounded(state:bool) -> void:
	if grounded != state:
		if state == true:
			# Transition to ground:
			air_transition_timer.stop()
			jumphold_framecount = 0
			has_jump = true
		else:
			# Transition to air:
			air_transition_timer.wait_time = 5.0 * frame_time
			air_transition_timer.start()
	grounded = state

# Jump leniency when falling off ledges
func _on_AirTransition_timeout() -> void:
	has_jump = false

 #####  ##  ##  #####   ##    ##  #####   ####   #####    ####   ##  ##
##      ##  ##  ##  ##  ##    ##  ##     ##  ##  ##  ##  ##  ##  ### ##
 ####   ##  ##  #####   ## ## ##  ####   ######  #####   ##  ##  ######
	##  ##  ##  ##  ##  ## ## ##  ##     ##  ##  ##      ##  ##  ## ###
#####    ####   #####    ######   #####  ##  ##  ##       ####   ##  ##

# Subweapons
func update_subweapon_state() -> void:
	if not shield.active:
		if Input.is_action_just_pressed("subweapon"):
			match(current_subweapon):
				"bomb":
					
					"""
					Current problems with bombs:
					- no custom shader logic, particles, lighting, etc.
					- no buffer system (tap twice to pull->throw)
					- awkward scene organization
					"""
					
					if bombspawner.holding: # If you are already holding the bomb, throw it.
						if bombspawner.can_throw_bomb():
							# I want to add a buffer system here so that if you double tap it will throw asap.
							# even if the pull anim is not finished.
							bombspawner.throw_bomb(forwards()*10.0 + Vector3.UP*5.0)
							set_locked(10)
					elif bombspawner.can_spawn_bomb(): # If a bomb can be spawned, do so.
						bombspawner.spawn_bomb()
						set_locked(10)
						
	if shield.active:
		if bombspawner.holding:
			bombspawner.drop_bomb()


func handle_collision(collision:KinematicCollision) -> void:
	# If a collision has occured:
	if collision:
		var impact:float = velocity.length()
		velocity = velocity.slide(collision.normal)
		impact -= velocity.length()
		if impact > 10.0:
			apply_damage(impact)

#####    ####   ######   ####   ######  ##   ####   ##  ##
##  ##  ##  ##    ##    ##  ##    ##    ##  ##  ##  ### ##
#####   ##  ##    ##    ######    ##    ##  ##  ##  ######
##  ##  ##  ##    ##    ##  ##    ##    ##  ##  ##  ## ###
##  ##   ####     ##    ##  ##    ##    ##   ####   ##  ##

func handle_player_rotation() -> void:
	if not locked:
		
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

#####   #####   ####  #####    ####   ##    ##  ##  ##
##  ##  ##     ##     ##  ##  ##  ##  ##    ##  ### ##
#####   ####    ###   #####   ######  ## ## ##  ######
##  ##  ##        ##  ##      ##  ##  ## ## ##  ## ###
##  ##  #####  ####   ##      ##  ##   ######   ##  ##

func respawn_check() -> void:
	# If player fell off the map, respawn
	if translation.y < -50:
		respawn()

func respawn() -> void:
	hp = 200.0
	translation = Vector3.ZERO
	velocity = Vector3.ZERO
	rotation = Vector3.ZERO
	set_locked(20)
	Game.cam.resetting = true

#####    ####    ######    ####    #####  #####
##  ##  ##  ##  ## ## ##  ##  ##  ##      ##
##  ##  ######  ## ## ##  ######  ## ###  ####
##  ##  ##  ##  ##    ##  ##  ##  ##  ##  ##
#####   ##  ##  ##    ##  ##  ##   ####   #####

func hit_by_explosion(explosion_center:Vector3) -> void:
	# Check if bomb hit your shield
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(explosion_center, self.position, [], Layers.actor)
	if result.size() > 0:
		if result.shape > 0:
			# hit shield
			var travel_vector = (self.position - explosion_center).normalized()
			velocity += forwards() * -10.0
			set_locked(10)
			return
	# Bomb did not hit your shield; apply damage.
	apply_damage(20)
	
func hit(collision:Dictionary) -> String:
		
	if collision.shape > 0: # hit shield
		return "bounce"
	else:
		apply_damage(10.0)
		return "die"

func apply_damage(value:float) -> void:
	set_locked(int(value))
	material.set_shader_param("damaged", true)
	if bombspawner.holding:
		bombspawner.drop_bomb()
	hp -= value
	if hp <= 0:
		die()
		
func die() -> void:
	respawn()

#####   #####  #####   ##  ##   #####
##  ##  ##     ##  ##  ##  ##  ## 
##  ##  ####   #####   ##  ##  ## ###
##  ##  ##     ##  ##  ##  ##  ##  ##
#####   #####  #####    ####    ####

func debug() -> void:
	# Debug Text
	Debug.text.write('Frame: ' + str(framecount))
	Debug.text.newline()
	Debug.text.write('HP: ' + str(hp))
	Debug.text.write('Subweapon: ' + str(current_subweapon))
	Debug.text.write('Jewels: ' + str(jewels))
	Debug.text.write('can_spawn_bomb()', 'green' if bombspawner.can_spawn_bomb() else 'red')
	Debug.text.newline()
	Debug.text.write('Vertical Velocity: ' + str(velocity.y))
	Debug.text.write('Horizontal Velocity: ' + str(Vector3(velocity.x, 0, velocity.z).length()))
#	Debug.text.write('Forward Direction: ' + str(forwards()))
	Debug.text.newline()
	Debug.text.write('Locked: ' + str(locked), 'green' if locked else 'red')
	Debug.text.write('Targeting: ' + str(targeting), 'green' if targeting else 'red')
	Debug.text.write('Grounded: ' + str(grounded), 'green' if grounded else 'red')
	Debug.text.write('Has Jump: ' + str(has_jump), 'green' if has_jump else 'red')
	Debug.text.write('Jumping: ' + str(jumping), 'green' if jumping else 'red')
	Debug.text.newline()
	Debug.text.write('Shielding: ' + str(shield.active), 'green' if shield.active else 'red')
	Debug.text.write('Bashing: ' + str(shield.bash_str), 'green' if shield.bash_str > 0.0 else 'red')
	Debug.text.newline()
	Debug.text.write('Sprinting: ' + str(sprint_count) + '/180')
#	Debug.text.write('Jumphold Framecount: ' + str(jumphold_framecount) + '/10')
	Debug.text.newline()
	if zl_target == 0:
		Debug.text.write("ZL Target: ")
	else:
		Debug.text.write("ZL Target: " + TargetSystem.list[zl_target].name, 'blue')
	Debug.text.newline()
	
	# Debug Draw
#	Debug.draw.begin(Mesh.PRIMITIVE_LINES)
#	Debug.draw.add_vertex(Game.player.position)
#	Debug.draw.add_vertex(Game.player.position + forwards())
#	Debug.draw.add_vertex(Game.player.position)
#	Debug.draw.add_vertex(Game.player.position + Vector3(velocity.x, 0, velocity.z).normalized())
#	Debug.draw.end()


