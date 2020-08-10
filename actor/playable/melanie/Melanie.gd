extends KinematicBody

 ######   ######  ##       ####   ##  ##  ##  ######
## ## ##  ##      ##      ##  ##  ### ##  ##  ##
## ## ##  #####   ##      ######  ######  ##  #####
##    ##  ##      ##      ##  ##  ## ###  ##  ##
##    ##  ######  ######  ##  ##  ##  ##  ##  ######

"""
Things to think about...
- External nodes currently alter player state sometimes, such as decreasing or increasing jewels.
Should this be changed?
"""

# Time
var framecount:int = 0

# Health
var hp:float = 200.0
var max_hp:float = 200.0

# Grounded State
var grounded:bool = true
onready var raycast = $RayCast # Determines if the player is grounded or not

# Movement
var velocity := Vector3.ZERO
var sprint_count:int = 0 # Track the # of consecutive frames the left joystick is fully pressed (for acceleration)

# Rotation
var look_target:Vector3 # used for Rotation

# Jumping
var has_jump:bool = true
var jumping:bool = false
var jumphold_framecount:int = 0 # Track the # of consecutive frames jump is held for (variable jump height)
onready var air_transition_timer = $Timers/AirTransition # Used to give jumps leniency when falling off of a ledge

# Shield
onready var shield = $ShieldAnim  # contains shield.active, a bool saying if shield is up or not

# Subweapons
var current_subweapon:String = "bomb"
var jewels:int = 999 setget update_jewel_count # Subweapon ammo
func update_jewel_count(value):
	jewels = value
	Events.emit_signal("jewel_count_changed")

const max_jewels:int = 999
onready var bombspawner = $BombSpawner

# Material
onready var material = $melanie_test/Armature/Skeleton/Face.get_surface_material(0)

# Interactables
onready var interactables = $Interactables

# Head Position
onready var head_position_node = $HeadPosition # Camera points at this, enemies attack this point.
var head_position:Vector3 setget , _get_head_position  # Gets Position3D global_transform.origin
func _get_head_position() -> Vector3:
	return head_position_node.global_transform.origin

#####   ######   ####   #####   ##  ##
##  ##  ##      ##  ##  ##  ##  ##  ##
#####   #####   ######  ##  ##   ####
##  ##  ##      ##  ##  ##  ##    ##
##  ##  ######  ##  ##  #####     ##

func _ready() -> void:
	process_priority = 0 # Run this before camera
	lockplayer_for_frames(20) # Set locked state

#####   #####    ####    #####  #####   #####   #####
##  ##  ##  ##  ##  ##  ##      ##     ##      ##
#####   #####   ##  ##  ##      ####    ####    #### 
##      ##  ##  ##  ##  ##      ##         ##      ##
##      ##  ##   ####    #####  #####  #####   ##### 

func _physics_process(_t) -> void:
	framecount += 1
	
	update_target_state() # ZL Targeting
	update_horizontal_velocity() # General movement
	update_vertical_velocity() # Jumping and gravity
	
	var collision:KinematicCollision = move_and_collide(velocity * Game.frame_time) # Apply Physics
	
	set_grounded(raycast.is_colliding()) # Check if grounded
	handle_collision(collision) # Redirect velocity, check landing impact, etc
	if velocity.length_squared() < 0.0001: velocity = Vector3.ZERO # If velocity is very small, make it 0
	handle_player_rotation() # Make player face the correct direction
	handle_interactable() # Pick up jewels, read text, etc.
	update_subweapon_state() # performed AFTER move_and_collide to correctly place projectiles.
	respawn_check() # Check if player fell below the map
	debug() # Write debug info onscreen

######  ####   #####    #####  ######  ######
  ##   ##  ##  ##  ##  ##      ##        ##
  ##   ######  #####   ## ###  #####     ##
  ##   ##  ##  ##  ##  ##  ##  ##        ##
  ##   ##  ##  ##  ##   ####   ######    ##

var targeting:bool = false # this variable is used a little weirdly at times...
var zl_target:int = 0 # which object are you targeting (0 for nothing)
onready var retarget_timer:Timer = $'Timers/ReTarget'
var retarget = 0 # which object were you just targeting

func update_target_state() -> void:
	
	if Input.is_action_just_pressed("L"):
		cam_reset_wall_align()
	
	# Begin ZL Targeting:
	if not targeting and Input.is_action_just_pressed("target"):
		
		if retarget == TargetSystem.priority_target and TargetSystem.secondary_target != 0:
			zl_target = TargetSystem.secondary_target
		else:
			zl_target = TargetSystem.priority_target
		
		cam_reset_wall_align()
	
	# Check if no longer targeting:
	if Input.is_action_pressed("target"):
		if not TargetSystem.target_is_valid(zl_target):
			# Target broken from distance or lost line of sight
			untarget()
	elif Game.cam.mode != "reset":
		untarget()
		
func untarget() -> void:
	if zl_target != 0:
		retarget = zl_target
		retarget_timer.start()
	zl_target = 0
	targeting = false

func _on_ReTarget_timeout() -> void:
	retarget = 0

func cam_reset_wall_align() -> void:
	targeting = true
	
	if zl_target == 0:
		Game.cam.reset()
		
		# align with wall if relevant
		var from = self.head_position
		var to =   self.head_position + forwards() * 0.25
		var result = get_world().direct_space_state.intersect_ray(from, to, [], Layers.solid)
		if result.size() > 0:
			look_at(translation - result.normal, Vector3.UP)

##  ##        ##  ##  #####  ##     ####    ####  ##  ######  ##  ##
##  ##        ##  ##  ##     ##    ##  ##  ##     ##    ##    ##  ##
######  ####  ##  ##  ####   ##    ##  ##  ##     ##    ##     ####
##  ##         ####   ##     ##    ##  ##  ##     ##    ##      ##
##  ##          ##    #####  #####  ####    ####  ##    ##      ##

""" Would be nice to add tap to change face dir without moving. """

func horizontal_velocity() -> Vector3:
	return Vector3(velocity.x, 0, velocity.z)

func update_horizontal_velocity() -> void:
	var move_vec = Vector3.ZERO # includes magnitude.
	var horizontal_velocity = horizontal_velocity()
	var interpolate_amt:float = 0.15
	
	# Aerial movement
	if not grounded:
		interpolate_amt = 0.015
		horizontal_velocity *= 0.999
	
	if shield.sliding:
		interpolate_amt = 0.025
	
	if not is_locked():
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
		if can_sprint():
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

func can_sprint() -> bool:
	if grounded and not shield.active and not targeting and not bombspawner.holding:
		return true
	return false

##  ##        ##  ##  #####  ##     ####    ####  ##  ######  ##  ##
##  ##        ##  ##  ##     ##    ##  ##  ##     ##    ##    ##  ##
##  ##  ####  ##  ##  ####   ##    ##  ##  ##     ##    ##     ####
 ####          ####   ##     ##    ##  ##  ##     ##    ##      ##
  ##            ##    #####  #####  ####    ####  ##    ##      ##

func update_vertical_velocity() -> void:
	# Apply Gravity
	velocity.y += Game.GRAVITY * Game.frame_time
	
	"""
	I feel like my jump code is very jank and I wish to change it at some point.
	I also need to add the other types of jumps.
	- Standing Jump
	- Running Jump
	- Backhop
	- Sidehop
	"""
	
	# Check for jumping
	if not is_locked():
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

"""
note: the damage lock overwrites the timer when you take dmg instead of adding more time.
I may want to change this later... maybe
"""

var lock_list:Array = []
onready var lock_timer = $Timers/Locked

func is_locked() -> bool:
	return lock_list.size() > 0

# Locked State:
func lockplayer_for_frames(frames:int) -> void:
	# Set Timer
	lock_timer.wait_time = frames * Game.frame_time
	lock_timer.start()
	lockplayer("timer")

func lockplayer(reason) -> void:
	if not lock_list.has(reason):
		lock_list.append(reason)
	jumping = false
	sprint_count = 0
	material.set_shader_param("locked", true)

func _on_Locked_timeout() -> void:
	unlockplayer("timer")
	
func unlockplayer(reason) -> void:
	lock_list.erase(reason)
	if not is_locked():
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
			air_transition_timer.wait_time = 5.0 * Game.frame_time
			air_transition_timer.start()
	grounded = state

# Jump leniency when falling off ledges
func _on_AirTransition_timeout() -> void:
	has_jump = false

##  ##  ##  ######  ######  #####    ####    #####  ######
##  ### ##    ##    ##      ##  ##  ##  ##  ##        ##
##  ######    ##    #####   #####   ######  ##        ##
##  ## ###    ##    ##      ##  ##  ##  ##  ##        ##
##  ##  ##    ##    ######  ##  ##  ##  ##   #####    ##

func handle_interactable():
	if grounded and not is_locked():
		if Input.is_action_just_pressed("X"):
			interactables.execute()

 #####  ##  ##  #####   ##    ##  #####   ####   #####    ####   ##  ## 
##      ##  ##  ##  ##  ##    ##  ##     ##  ##  ##  ##  ##  ##  ### ## 
 ####   ##  ##  #####   ## ## ##  ####   ######  #####   ##  ##  ###### 
    ##  ##  ##  ##  ##  ## ## ##  ##     ##  ##  ##      ##  ##  ## ### 
#####    ####   #####    ######   #####  ##  ##  ##       ####   ##  ## 

"""
I think it's plausible that there could be a Subweapon node that performs
all of the processing of the subweapon state, similar to how shield works.
"""

# Subweapons
func update_subweapon_state() -> void:
	match(current_subweapon):
		"bomb":
			bombspawner.process_state()
 
 ####   ####   ##     ##     ##   #####  ##   ####   ##  ##
##     ##  ##  ##     ##     ##  ##      ##  ##  ##  ### ##
##     ##  ##  ##     ##     ##   ####   ##  ##  ##  ######
##     ##  ##  ##     ##     ##      ##  ##  ##  ##  ## ###
 ####   ####   #####  #####  ##  #####   ##   ####   ##  ##

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

func forwards() -> Vector3:
	return -transform.basis.z

func handle_player_rotation() -> void:
	if not is_locked():
		
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

var checkpoint:Dictionary = {
		"position": Vector3.ZERO,
		"jewels": 50,
		"subweapon": "bomb",
		"y_rotation": 0.0
	}

func respawn_check() -> void:
	# If player fell off the map, respawn
	if translation.y < -50:
		respawn()

func respawn() -> void:
	hp = max_hp
	Events.emit_signal("player_respawning")
	velocity = Vector3.ZERO
	
	translation = checkpoint.position
	rotation = Vector3(0, checkpoint.y_rotation, 0)
	current_subweapon = checkpoint.subweapon
	self.jewels = checkpoint.jewels
	
	lockplayer_for_frames(20)
	Game.cam.reset()

#####    ####    ######    ####    #####  #####
##  ##  ##  ##  ## ## ##  ##  ##  ##      ##
##  ##  ######  ## ## ##  ######  ## ###  ####
##  ##  ##  ##  ##    ##  ##  ##  ##  ##  ##
#####   ##  ##  ##    ##  ##  ##   ####   #####

func hit_by_explosion(explosion_center:Vector3) -> void:
	# Check if bomb hit your shield
	var travel_vector = (self.head_position - explosion_center).normalized()
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(explosion_center, self.head_position, [], Layers.actor)
	if result.size() > 0:
		if result.shape > 0:
			# hit shield
			velocity += forwards() * -14.0
			shield.slide()
			return
	# Bomb did not hit your shield; apply damage.
	velocity += travel_vector * 7.0
	apply_damage(30)
	
func hit(collision:Dictionary) -> String:
		
	if collision.shape > 0: # hit shield
		return "bounce"
	else:
		apply_damage(10.0)
		return "die"

func apply_damage(value:float) -> void:
	lockplayer_for_frames(int(value))
	material.set_shader_param("damaged", true)
	hp -= value
	if hp <= 0:
		hp = 0
		die()
	Events.emit_signal('player_damaged')
		
func die() -> void:
	#Events.emit_signal('player_died')
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
#	Debug.text.write('HP: ' + str(hp))
#	Debug.text.write('Subweapon: ' + str(current_subweapon))
#	Debug.text.write('Jewels: ' + str(jewels))
#	Debug.text.write('can_spawn_bomb()', 'green' if bombspawner.can_spawn_bomb() else 'red')
#	Debug.text.newline()
	Debug.text.write('Vertical Velocity: ' + str(velocity.y))
	Debug.text.write('Horizontal Velocity: ' + str(horizontal_velocity().length()))
#	Debug.text.write('Forward Direction: ' + str(forwards()))
	Debug.text.newline()
	Debug.text.write('Targeting', 'green' if targeting else 'red')
	Debug.text.write('ReTarget: ' + str(retarget), 'green' if retarget > 0 else 'red')
	if zl_target == 0:
		Debug.text.write("ZL Target: ")
	else:
		Debug.text.write("ZL Target: " + str(zl_target), 'blue')
	Debug.text.newline()
	Debug.text.write('Locked: ' + str(lock_list), 'green' if is_locked() else 'red')
	Debug.text.write('Grounded: ' + str(grounded), 'green' if grounded else 'red')
	Debug.text.write('Has Jump: ' + str(has_jump), 'green' if has_jump else 'red')
	Debug.text.write('Jumping: ' + str(jumping), 'green' if jumping else 'red')
	Debug.text.newline()
	Debug.text.write('Shielding: ' + str(shield.active), 'green' if shield.active else 'red')
	Debug.text.write('Bashing: ' + str(shield.bash_str), 'green' if shield.bash_str > 0.0 else 'red')
	Debug.text.write('Sliding: ' + str(shield.sliding), 'green' if shield.sliding else 'red')
	Debug.text.newline()
	Debug.text.write('Sprinting: ' + str(sprint_count) + '/180')
#	Debug.text.write('Jumphold Framecount: ' + str(jumphold_framecount) + '/10')
	Debug.text.newline()
	Debug.text.write('Interactables: ' + str(interactables.list))

	# Debug Draw
#	Debug.draw.begin(Mesh.PRIMITIVE_LINES)
#	Debug.draw.add_vertex(Game.player.head_position)
#	Debug.draw.add_vertex(Game.player.head_position + forwards())
#	Debug.draw.add_vertex(Game.player.head_position)
#	Debug.draw.add_vertex(Game.player.head_position + Vector3(velocity.x, 0, velocity.z).normalized())
#	Debug.draw.end()



