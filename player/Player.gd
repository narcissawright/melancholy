extends KinematicBody

#####   ##       ####   ##  ##  ######  ##### 
##  ##  ##      ##  ##  ##  ##  ##      ##  ##
#####   ##      ######   ####   #####   #####
##      ##      ##  ##    ##    ##      ##  ##
##      ######  ##  ##    ##    ######  ##  ##

"""
New plan. Handle both characters from this script.
"""

# Current Character
var character:String = "Melanie"

# Time
var framecount:int = 0
var frame_time:float = 1.0 / 60.0

# Health
var hp:float = 200.0
var max_hp:float = 200.0

# Movement
var velocity := Vector3.ZERO
var sprint_count:int = 0 # Track the # of consecutive frames the left joystick is fully pressed (for acceleration)

# Shield
onready var shield = $ShieldAnim  # contains shield.active, a bool saying if shield is up or not

# Material
onready var material = $MelanieModel/Armature/Skeleton/MeshInstance.get_surface_material(0)

# Head Position
onready var head_position_node = $HeadPosition # Camera points at this, enemies attack this point.
var head_position:Vector3 setget , _get_head_position
func _get_head_position() -> Vector3:
	return head_position_node.global_transform.origin

# AnimationTree
onready var anim_tree = $AnimationTree

#####   ######   ####   #####   ##  ##
##  ##  ##      ##  ##  ##  ##  ##  ##
#####   #####   ######  ##  ##   ####
##  ##  ##      ##  ##  ##  ##    ##
##  ##  ######  ##  ##  #####     ##

func _ready() -> void:
	initialize_animationtree()
	initialize_checkpoint_state()
	lockplayer_for_frames(20)

#####   #####    ####    #####  #####   #####   #####
##  ##  ##  ##  ##  ##  ##      ##     ##      ##
#####   #####   ##  ##  ##      ####    ####    #### 
##      ##  ##  ##  ##  ##      ##         ##      ##
##      ##  ##   ####    #####  #####  #####   ##### 

func _physics_process(_t:float) -> void:
	framecount += 1
	
	# None of these functions should be called outside of _physics_process
	# They are separate functions purely for organizational purposes,
	# but they are effectively sequential code.
	check_if_use_item() # Item Usage
	update_target_state() # ZL Targeting
	
	check_ledgegrab()
	update_horizontal_velocity() # General movement
	jumping_and_falling()
	
	var collision:KinematicCollision = move_and_collide(velocity * frame_time) # Apply Physics
	
	set_grounded(raycast.is_colliding()) # Check if grounded
	handle_collision(collision) # Redirect velocity, check landing impact, etc
	if velocity.length_squared() < 0.0001: velocity = Vector3.ZERO # If velocity is very small, make it 0
	walk_animation()
	handle_player_rotation() # Make player face the correct direction
	handle_interactable() # Pick up jewels, read text, etc.
	process_subweapon() # performed AFTER move_and_collide to correctly place projectiles.
	respawn_check() # Check if player fell below the map
	debug() # Write debug info onscreen

##     ####    ####  ##  ##  ######  #####
##    ##  ##  ##     ## ##   ##      ##  ##
##    ##  ##  ##     ####    #####   ##  ##
##    ##  ##  ##     ## ##   ##      ##  ##
#####  ####    ####  ##  ##  ######  #####

var lock_list:Array = []
onready var lock_timer = $Timers/LockPlayer

func is_locked() -> bool:
	return lock_list.size() > 0

func lockplayer_for_frames(frames:int, overwrite:bool = false) -> void:
	# Set Timer
	lock_timer.wait_time = (frames * frame_time)
	if not overwrite:
		lock_timer.wait_time += lock_timer.time_left
	lock_timer.start()
	lockplayer("timer")

func lockplayer(reason) -> void:
	if not lock_list.has(reason):
		lock_list.append(reason)
	material.set_shader_param("locked", true)

func _on_LockPlayer_timeout() -> void:
	unlockplayer("timer")
	
func unlockplayer(reason) -> void:
	lock_list.erase(reason)
	if not is_locked():
		material.set_shader_param("locked", false)
		material.set_shader_param("damaged", false)

##  ##  ##  #####   ##  ##  ######
##  ### ##  ##  ##  ##  ##    ##
##  ######  #####   ##  ##    ##
##  ## ###  ##      ##  ##    ##
##  ##  ##  ##       #####    ##

# Joystick input at least.

var joystick_outer_threshold = 0.9
var joystick_axis_deadzone = 0.15
func get_stick_input(which:String) -> Vector2:
	"""
	this function takes in 'left' or 'right'
	referring to the left and right control sticks on the joypad
	it returns an altered input that accounts for deadzones.
	"""
	# get raw input
	var axes:Vector2
	if which == 'left':
		axes = Vector2(Input.get_joy_axis(0, 0), Input.get_joy_axis(0, 1))
	elif which == 'right':
		axes = Vector2(Input.get_joy_axis(0, 2), Input.get_joy_axis(0, 3))

	if abs(axes.x) < joystick_axis_deadzone:
		axes.x = 0.0
	if abs(axes.y) < joystick_axis_deadzone:
		axes.y = 0.0
		if axes.x == 0.0:
			return Vector2.ZERO # No input.
	
	var length = axes.length()
	var normalized = axes.normalized()
	
	if length > joystick_outer_threshold:
		return normalized # Max input
	
	var percentage = inverse_lerp(joystick_axis_deadzone, joystick_outer_threshold, length)
#	percentage = pow(percentage, joystick_easing_curve)
	return normalized * percentage

# Converts joystick input to world space, using Camera as the basis
func find_movement_direction() -> Vector3:
	var pushdir := Vector2.ZERO
	if Input.is_action_pressed("move_up"):
		pushdir.y -= 1
	if Input.is_action_pressed("move_down"):
		pushdir.y += 1
	if Input.is_action_pressed("move_left"):
		pushdir.x -= 1
	if Input.is_action_pressed("move_right"):
		pushdir.x += 1
	if pushdir == Vector2.ZERO:
		pushdir = get_stick_input("left")
	var camdir:Vector3 = MainCam.global_transform.basis.z
	camdir.y = 0.0
	camdir = camdir.normalized()
	return (camdir * pushdir.y) + (camdir.rotated(Vector3.UP, PI/2) * pushdir.x)

##  ######  ######   ###### 
##    ##    ##      ## ## ##
##    ##    ####    ## ## ##
##    ##    ##      ##    ##
##    ##    ######  ##    ##

var inventory = []

func inventory_is_full() -> bool:
	return inventory.size() >= 5

func obtain_item(item:String) -> void:
	inventory.append(item)
	UI.inventory.update_inventory(inventory)

func can_use_item() -> bool:
	if not grounded: return false
	if is_locked(): return false
	if MainCam.mode == "first_person": return false 
	return true

func check_if_use_item() -> void:
	if Input.is_action_just_pressed("use_item"):
		if can_use_item():
			match UI.inventory.current_item():
				"sun_card":
					if Timekeeper.can_use_card():
						Timekeeper.use_card("sun")
						inventory.remove(UI.inventory.selected_item)
						UI.inventory.selected_item = 0
						UI.inventory.update_inventory(inventory)
						lockplayer_for_frames(30)
				"moon_card":
					if Timekeeper.can_use_card():
						Timekeeper.use_card("moon")
						inventory.remove(UI.inventory.selected_item)
						UI.inventory.selected_item = 0
						UI.inventory.update_inventory(inventory)
						lockplayer_for_frames(30)

######  ####   #####    #####  ######  ######
  ##   ##  ##  ##  ##  ##      ##        ##
  ##   ######  #####   ## ###  #####     ##
  ##   ##  ##  ##  ##  ##  ##  ##        ##
  ##   ##  ##  ##  ##   ####   ######    ##

onready var TargetSystem = $TargetSystem

var targeting:bool = false # this variable is used a little weirdly at times...
var zl_target:int = 0 # which object are you targeting (0 for nothing)
onready var retarget_timer:Timer = $'Timers/ReTarget'
var retarget = 0 # which object were you just targeting

onready var skele = $MelanieModel/Armature/Skeleton
onready var head_bone_idx = skele.find_bone("head")

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
	elif MainCam.mode != "reset":
		untarget()
		
	#head_rotation()
		
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
		MainCam.reset()
		
		# align with wall if relevant
		wall_align(0.25)

func wall_align(dist:float) -> void:
	var from = self.head_position
	var to =   self.head_position + forwards() * dist
	var result = get_world().direct_space_state.intersect_ray(from, to, [], Layers.solid)
	if result.size() > 0:
		safe_look_at(-result.normal)

##      ######  #####    #####  ######
##      ##      ##  ##  ##      ##
##      #####   ##  ##  ## ###  #####
##      ##      ##  ##  ##  ##  ##
######  ######  #####    ####   ######

onready var ledgesystem:Spatial = $LedgeGrabSystem
onready var ledgegrab_tween:Tween = $LedgeGrabSystem/Tween
var ledgegrabbing:bool = false

""" 
Known issues:
	- no detection of where ledges end, which means you can move onto walls.
	- bad detection with sloped walls
"""

func check_ledgegrab():
	if ledgegrabbing:
		if not Input.is_action_pressed("jump"):
			let_go_of_ledge()
			return
		
		if not ledgegrab_tween.is_active():
			""" Sometimes this is_active even when a tween isnt occuring... causing problems """
			var dir = find_movement_direction()
			var hray_result = ledgesystem.horizontal_raycast(transform.origin.y + 2.0)
			match hray_result.hits:
				0:
					let_go_of_ledge()
				1:
					let_go_of_ledge()
				2:
					hray_result.normal.y = 0.0
					hray_result.normal = hray_result.normal.normalized()
					if not hray_result.normal.is_equal_approx(transform.basis.z):
						# Rotation
						rotate_towards_ledge(hray_result.normal)
						# Position
						var goal_translation := Vector3()
						goal_translation.x = hray_result.position.x + hray_result.normal.x * 0.2
						goal_translation.y = translation.y
						goal_translation.z = hray_result.position.z + hray_result.normal.z * 0.2
						move_and_collide(goal_translation - translation)
					
					# Need to prevent movement when there is no longer a ledge.
					var cross = hray_result.normal.cross(Vector3.UP)
					velocity = cross * clamp((cross.dot(dir) * 2.0), -1, 1)
					# I can't jut set the velocity here. I need to check if it's a valid position to go to.
					
					Debug.text.write(str(velocity))
	else:
		# Check for initiate ledge grab:
		if grounded: return
		if is_locked(): return
		if velocity.y >= 0.1: return
		if not Input.is_action_pressed("jump"): return 
		if bombspawner.holding: return
		if shield.active: return
		
		# check if player ledgegrab colliders are in correct position
		var ledgegrab_result:Dictionary = ledgesystem.try_ledgegrab()
		if ledgegrab_result.can_ledgegrab == false: return
		
		# find wall position and normal
		var hray_result = ledgesystem.horizontal_raycast(ledgegrab_result.height)
		if hray_result.hits > 0:
			
			# initiate ledge grab. 
			velocity = Vector3.ZERO
			ledgegrabbing = true
			snap_to_ledge(hray_result, ledgegrab_result.height)

func let_go_of_ledge() -> void:
	ledgegrabbing = false
	set_ledge_cling_anim(0.0)
	ledgegrab_tween.stop_all()

func rotate_towards_ledge(wall_normal:Vector3) -> void:
	var old_basis = global_transform.basis
	safe_look_at(-wall_normal)
	var goal_basis:Basis = global_transform.basis
	global_transform.basis = old_basis
	
	ledgegrab_tween.interpolate_property(self, "global_transform:basis", 
		global_transform.basis, goal_basis, 0.15,
		Tween.TRANS_SINE, Tween.EASE_OUT)
	ledgegrab_tween.start()

func snap_to_ledge(raycast_result:Dictionary, height:float) -> void:
	# find new transform basis
	var old_basis = global_transform.basis
	safe_look_at(-raycast_result.normal)
	var goal_basis:Basis = global_transform.basis
	global_transform.basis = old_basis
	
	# find new transform origin.
	""" 
	WARNING
	clipping glitch on low slope ledge
	needs to be fixed
	"""

	var goal_translation := Vector3()
	goal_translation.x = raycast_result.position.x + raycast_result.normal.x * 0.2
	goal_translation.z = raycast_result.position.z + raycast_result.normal.z * 0.2
	goal_translation.y = height - 2.0
	
	# interpolate to new transform.
	ledgegrab_tween.interpolate_property(self, "global_transform", 
		global_transform, Transform(goal_basis, goal_translation), 0.15,
		Tween.TRANS_SINE, Tween.EASE_OUT)
	
	ledgegrab_tween.interpolate_method(self, "set_ledge_cling_anim", 
		0.0, 1.0, 0.15,
		Tween.TRANS_SINE, Tween.EASE_OUT)
		
	ledgegrab_tween.start()

##  ##        ##  ##  #####  ##     ####    ####  ##  ######  ##  ##
##  ##        ##  ##  ##     ##    ##  ##  ##     ##    ##    ##  ##
######  ####  ##  ##  ####   ##    ##  ##  ##     ##    ##     ####
##  ##         ####   ##     ##    ##  ##  ##     ##    ##      ##
##  ##          ##    #####  #####  ####    ####  ##    ##      ##

""" Would be nice to add tap to change face dir without moving. """

func horizontal_velocity() -> Vector3:
	return Vector3(velocity.x, 0, velocity.z)

func update_horizontal_velocity() -> void:
	if ledgegrabbing:
		return
	if jump_state == "jump_squat":
		return
	
	var move_vec = Vector3.ZERO # includes magnitude.
	var horizontal_velocity = horizontal_velocity()
	var interpolate_amt:float = 0.15
	
	# Aerial movement
	if not grounded:
		interpolate_amt = 0.015
		horizontal_velocity *= 0.999
	
	if shield.sliding:
		interpolate_amt = 0.025
	
	if is_locked():
		sprint_count = 0
	else:
		# Left Stick Movement
		var direction:Vector3 = find_movement_direction()
		look_target = look_target.linear_interpolate(direction, 0.15)
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

func can_sprint() -> bool:
	if grounded and not shield.active and not targeting and not bombspawner.holding:
		return true
	return false

   ##  ##  ##   #####   #####
   ##  ##  ##  ## # ##  ##  ##
   ##  ##  ##  ## # ##  #####
   ##  ##  ##  ##   ##  ##
####    ####   ##   ##  ##

var jump_state:String = "has_jump" # "falling" "jump_squat" "landing" # etc
var shorthop:bool = false
var buffer_jump:bool = false
var jumpsquat_framecount:int = 0
var floor_normal:Vector3
onready var buffer_jump_timer = $Timers/BufferJump

func check_buffer_jump() -> void:
	if Input.is_action_just_pressed("jump"):
		buffer_jump_timer.start(0.1)

func jumping_and_falling() -> void:
	check_buffer_jump()
	
	if ledgegrabbing:
		return
	
	# Apply Gravity
	velocity.y += Level.GRAVITY * frame_time
	
	# Check for jumping
	if not Player.is_locked():
		match jump_state:
			"has_jump":
				if not buffer_jump_timer.is_stopped():
					initiate_jump()
			"jump_squat":
				jumpsquat_framecount += 1
				
				if not Input.is_action_pressed('jump'):
					shorthop = true
					
				if jumpsquat_framecount >= 4: # time's up!
					# determine which jump type it is here.
					
					var late:bool = false
					if not air_transition_timer.is_stopped():
						late = true # Jump initiated while airbourne
					
					var movedir:Vector3 = Player.find_movement_direction()
					var standing_vs_running:float = (movedir.length() + min(horizontal_velocity().length() / 8.0, 1.0)) / 2.0
					
					if not targeting:
						# not targeting, so do a normal jump.
						normal_jump(standing_vs_running, late)
					else:
						# Approach forward if the stick isn't being held all the way.
						var inverse = 1.0 - movedir.length()
						var check_angle = (forwards() * inverse) + (movedir)
						var angle:float = angle_to_flattened(forwards(), check_angle)
						
						if abs(angle) < PI/4:
							normal_jump(standing_vs_running, late)
						else:
							# side/back hop
							var jump_velocity:Vector3 = (forwards().rotated(Vector3.UP, -angle) * 4.0) + (floor_normal * 4.0)
							if shield.active: jump_velocity *= 0.5
							velocity += jump_velocity
							jump_state = "falling"

func initiate_jump() -> void:
	jump_state = "jump_squat"
	jumpsquat_framecount = 0
	shorthop = false
	if raycast.is_colliding():
		floor_normal = raycast.get_collision_normal()
		if floor_normal != Vector3.UP:
			floor_normal = floor_normal.linear_interpolate(Vector3.UP, 0.5)
	else:
		floor_normal = Vector3.UP
	anim_state_machine.travel("Jump")

func normal_jump(stand_vs_run:float, late:bool) -> void:
	var jump_velocity:Vector3 = floor_normal * (9.0 + 2.0 * (1.0 - (stand_vs_run)))
	if late:
		jump_velocity += Player.forwards()
		jump_velocity.y *= 0.9
	if shorthop: jump_velocity *= 0.66667
	if shield.active: jump_velocity *= 0.5
	velocity += jump_velocity
	jump_state = "falling"

 #####  #####    ####   ##  ##  ##  ##  #####   ######  #####
##      ##  ##  ##  ##  ##  ##  ### ##  ##  ##  ##      ##  ##
## ###  #####   ##  ##  ##  ##  ######  ##  ##  #####   ##  ##
##  ##  ##  ##  ##  ##  ##  ##  ## ###  ##  ##  ##      ##  ##
 ####   ##  ##   ####    ####   ##  ##  #####   ######  #####

var grounded:bool = true
onready var raycast = $RayCast # Determines if the player is grounded or not
onready var air_transition_timer = $Timers/AirTransition # Used to give jumps leniency when falling off of a ledge

# Grounded State:
func set_grounded(state:bool) -> void:
	if grounded != state:
		if state == true:
			# Transition to ground:
			air_transition_timer.stop()
			jump_state = "has_jump"
			anim_state_machine.travel("BaseMovement")
		else:
			# Transition to air:
			air_transition_timer.start()
			anim_state_machine.travel("Falling")
	grounded = state

# Jump leniency when falling off ledges
func _on_AirTransition_timeout() -> void:
	jump_state = "falling"

 ####   ##  ##  ##   ######
##  ##  ### ##  ##  ## ## ##
######  ######  ##  ## ## ##
##  ##  ## ###  ##  ##    ##
##  ##  ##  ##  ##  ##    ##

"""
Note that other animations may be called elsewhere.
e.g. BombSpawner or Bomb may call bomb pull or bomb throw.
"""

var anim_state_machine
func initialize_animationtree() -> void:
	anim_state_machine = anim_tree['parameters/playback']
	anim_state_machine.start("BaseMovement")

func walk_animation() -> void:
	if jump_state == 'landing':
		anim_tree['parameters/BaseMovement/BlendSpace2D/blend_position'] = Vector2.ZERO
		anim_tree['parameters/BaseMovement/TimeScale/scale'] = 1.0
		return
	
	var h_velocity = horizontal_velocity()
	var angle = angle_to_flattened(h_velocity, forwards())
	var walk_length = min(h_velocity.length() / 8.0, 1.0)
	var blend_pos:Vector2 = Vector2(sin(-angle), 1.0 - abs(sin(angle))) * walk_length
	
	Debug.text.write("ANGLE: " + str(angle))
	Debug.text.write("BLEND_POS: " + str(blend_pos))
	Debug.text.write("WALK_LEN: " + str(walk_length))
	
	
#
#	var x_walk = sign(angle) * min(h_velocity.length() * (1.0 - abs(angle/PI)), 4.0) / 4.0
#	var y_walk = min(h_velocity.length() * abs(angle/PI), 8.0) / 8.0
	
	anim_tree['parameters/BaseMovement/BlendSpace2D/blend_position'] = blend_pos
	anim_tree['parameters/BaseMovement/TimeScale/scale'] = 1.0 + abs(blend_pos.y/2.0)
	
func set_ledge_cling_anim(_blend_amt:float) -> void:
	pass
	#anim_tree['parameters/is_ledge_clinging/blend_amount'] = blend_amt
	
""" 
Head Rotation Failure.
Waiting for IK improvements to work on this.
"""
func head_rotation() -> void:
	var head_look_target:int = TargetSystem.priority_target
	if head_look_target != 0:
		var custom_pose = skele.get_bone_custom_pose(head_bone_idx)
		var face_dir = global_transform.basis.xform(-custom_pose.basis.z)

		# this line can crash.
		var head_looktowards:Vector3 = (TargetSystem.list[head_look_target].pos - self.head_position).normalized()

		head_looktowards.y = clamp(head_looktowards.y, -0.35, 0.35)
		face_dir.y = clamp(face_dir.y, -0.35, 0.35)

		var hlt_xz = Vector2(head_looktowards.x, head_looktowards.z).normalized()
		var face2d = Vector2(face_dir.x, face_dir.z).normalized()

		# warning-ignore:unused_variable
		var diff_2d = (face2d.angle_to(hlt_xz))
		var updown_rot:float = (head_looktowards.y - face_dir.y)

		#I think now the problem is that the 2nd axis i am rotating on no longer makes sense once it has already been rotated once.
		#Need to figure out a clean way to get this going.
		custom_pose.basis = custom_pose.basis.rotated(Vector3(1,0,0), updown_rot) # UP DOWN
		#custom_pose.basis = custom_pose.basis.rotated(Vector3(0,1,0), 0.0) # TILT
		#custom_pose.basis = custom_pose.basis.rotated(custom_pose.basis.z, diff_2d) # LEFT/RIGHT
		skele.set_bone_custom_pose(head_bone_idx, custom_pose)
	else:
		skele.set_bone_custom_pose(head_bone_idx, Transform())

##  ##  ##  ######  ######  #####    ####    #####  ######
##  ### ##    ##    ##      ##  ##  ##  ##  ##        ##
##  ######    ##    #####   #####   ######  ##        ##
##  ## ###    ##    ##      ##  ##  ##  ##  ##        ##
##  ##  ##    ##    ######  ##  ##  ##  ##   #####    ##

onready var interactables = $Interactables

func handle_interactable():
	if grounded and not Player.is_locked():
		if Input.is_action_just_pressed("X"):
			interactables.execute()

 #####  ##  ##  #####   ##    ##  #####   ####   #####    ####   ##  ## 
##      ##  ##  ##  ##  ##    ##  ##     ##  ##  ##  ##  ##  ##  ### ## 
 ####   ##  ##  #####   ## ## ##  ####   ######  #####   ##  ##  ###### 
    ##  ##  ##  ##  ##  ## ## ##  ##     ##  ##  ##      ##  ##  ## ### 
#####    ####   #####    ######   #####  ##  ##  ##       ####   ##  ## 

var current_subweapon:String = "" setget new_subweapon
func new_subweapon(what:String) -> void:
	current_subweapon = what
	Events.emit_signal("current_subweapon_changed")
	# some logic here to drop the old subweapon.

const max_jewels:int = 999
var jewels:int = 25 setget update_jewel_count # Subweapon ammo
func update_jewel_count(value):
	jewels = value
	Events.emit_signal("jewel_count_changed")

onready var bombspawner = $BombSpawner
onready var bomb_pos = $MelanieModel/Armature/Skeleton/BombPos

# Subweapons
func process_subweapon() -> void:
	match(current_subweapon):
		"":
			if Input.is_action_just_pressed("subweapon"):
				Events.emit_signal("error_no_subweapon")
		"bomb":
			bombspawner.translation.y = bomb_pos.translation.y
			bombspawner.translation.z = -bomb_pos.translation.z
			bombspawner.translation.x = -bomb_pos.translation.x
			bombspawner.process_state()
 
 ####   ####   ##     ##     ##   #####  ##   ####   ##  ##
##     ##  ##  ##     ##     ##  ##      ##  ##  ##  ### ##
##     ##  ##  ##     ##     ##   ####   ##  ##  ##  ######
##     ##  ##  ##     ##     ##      ##  ##  ##  ##  ## ###
 ####   ####   #####  #####  ##  #####   ##   ####   ##  ##

var gather_collision_data = false
var collision_locations = {}
onready var collision_data_timer = $Timers/CollisionData

# Collision Data for grass/paths
var geometry_aabb:AABB
var path_collision_img:Image
var path_collision_tex:ImageTexture

func handle_collision(collision:KinematicCollision) -> void:
	# If a collision has occured:
	if collision:
		var impact:float = velocity.length()
		velocity = velocity.slide(collision.normal)
		impact -= velocity.length()
		if impact > 12.5:
			apply_damage(impact * 1.5)
		
		if gather_collision_data:
			_gather_collision_data()

""" 
The code below here is for making dirt paths by running on grass.
This code was neat to make but I actually have been perhaps convinced
that a cleaner solution is to set vertex color data for grass mesh
instead of storing this 3d image for the entire level AABB
which is wasteful.

Having the code here in the player script is maybe weird too,
it could live elsewhere.
"""

func _gather_collision_data():
	# Gather location information
	if collision_data_timer.is_stopped():
		if velocity.length() > 5.0:
			collision_data_timer.start()
			var position = translation.round()
			var offset = translation - position
			
			var x_dir = sign(offset.x)
			var y_dir = sign(offset.y)
			var z_dir = sign(offset.z)
			
			var locations = [
				position, 
				position + Vector3(0,     0,     z_dir),
				position + Vector3(0,     y_dir, 0    ),
				position + Vector3(0,     y_dir, z_dir),
				position + Vector3(x_dir, 0,     0    ),
				position + Vector3(x_dir, 0,     z_dir),
				position + Vector3(x_dir, y_dir, 0    ),
				position + Vector3(x_dir, y_dir, z_dir)
			]
			
			for i in range (locations.size()):
				var index:int = get_collision_img_index(locations[i], geometry_aabb)
				var distance = (translation - locations[i]).length()
				var value:int = int((1.0 - distance) * 0x0F)
				if value > 0:
					set_collision_img_data(index, value)

func get_collision_img_index(position:Vector3, aabb:AABB) -> int:
	var diff:Vector3 = position - aabb.position
	return int(diff.x + (diff.y * aabb.size.x) + (diff.z * aabb.size.x * aabb.size.y))

func set_collision_img_data(index:int, value:int) -> void:
	var img_data = path_collision_img.data.data
	var old_value = img_data[index]
	var new_value = min(old_value + value, 0xFF)
	img_data.set(index, new_value)
	path_collision_img.data.data = img_data
	# warning-ignore:integer_division
	var y = index / 1024
	var x = index % 1024
	VisualServer.texture_set_data_partial(path_collision_tex.get_rid(), path_collision_img, x, y, 1, 1, x, y, 0)

""" This should run once per level at the start """
func set_geometry_aabb(aabb:AABB) -> void:
	gather_collision_data = true
	geometry_aabb = aabb
	var height = ceil((aabb.size.x+1) * (aabb.size.y+1) * (aabb.size.z+1) / 1024.0)
	path_collision_img = Image.new()
	path_collision_img.create(1024, height, false, Image.FORMAT_L8)
	path_collision_tex = ImageTexture.new()
	path_collision_tex.create_from_image(path_collision_img, 0)
	$TextureRect.texture = path_collision_tex
	Level.get_node("level1/Geometry").get_surface_material(0).set_shader_param("collision_data", path_collision_tex)

#####    ####   ######   ####   ######  ##   ####   ##  ##
##  ##  ##  ##    ##    ##  ##    ##    ##  ##  ##  ### ##
#####   ##  ##    ##    ######    ##    ##  ##  ##  ######
##  ##  ##  ##    ##    ##  ##    ##    ##  ##  ##  ## ###
##  ##   ####     ##    ##  ##    ##    ##   ####   ##  ##

var look_target := Vector3.ZERO # used for Rotation

func forwards() -> Vector3:
	return -global_transform.basis.z

func handle_player_rotation() -> void:
	#print (Player.is_locked(), MainCam.mode, look_target)

	if is_locked() or not grounded:
		return

	# While not targeting: Look towards movement direction
	if not targeting:
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
		safe_look_at(lookdir)

# safe rotation, removed y component so the body will never skew weirdly.
func safe_look_at(lookdir:Vector3) -> void:
	lookdir.y = 0.0 
	lookdir = lookdir.normalized()
	if lookdir.is_equal_approx(Vector3.ZERO): return
	look_at(lookdir + translation, Vector3.UP)


# FIRST PERSON

func enter_first_person() -> void:
	if shield.active:
		shield.put_away()
	if bombspawner.holding:
		bombspawner.drop_bomb()
	untarget()
	lockplayer("first_person")

func exit_first_person() -> void:
	buffer_jump_timer.stop() # prevent jump from firing if you use A to exit first person.
	safe_look_at(-MainCam.current_pos)
	unlockplayer("first_person")


#####   #####   ####  #####    ####   ##    ##  ##  ##
##  ##  ##     ##     ##  ##  ##  ##  ##    ##  ### ##
#####   ####    ###   #####   ######  ## ## ##  ######
##  ##  ##        ##  ##      ##  ##  ## ## ##  ## ###
##  ##  #####  ####   ##      ##  ##   ######   ##  ##

var checkpoint:Dictionary = {
		"time_of_day": 0.0,
		"position": Vector3.ZERO,
		"jewels": 0,
		"subweapon": "",
		"y_rotation": 0.0, 
		"inventory": []
	}

func initialize_checkpoint_state() -> void:
	checkpoint.jewels = jewels
	checkpoint.subweapon = current_subweapon
	checkpoint.time_of_day = Timekeeper.time_of_day
	checkpoint.inventory = inventory.duplicate()

func respawn_check() -> void:
	# If player fell off the map, respawn
	if translation.y < -50:
		respawn()

func respawn() -> void:
	hp = max_hp
	Events.emit_signal("respawn")
	velocity = Vector3.ZERO
	
	translation = checkpoint.position
	rotation = Vector3(0, checkpoint.y_rotation, 0)
	self.current_subweapon = checkpoint.subweapon
	self.jewels = checkpoint.jewels
	Timekeeper.time_of_day = checkpoint.time_of_day
	inventory = checkpoint.inventory.duplicate()
	UI.inventory.selected_item = 0
	UI.inventory.update_inventory(inventory)
	
	Player.lockplayer_for_frames(20, true) # Overwrite the timer
	MainCam.reset()

#####    ####    ######    ####    #####  #####
##  ##  ##  ##  ## ## ##  ##  ##  ##      ##
##  ##  ######  ## ## ##  ######  ## ###  ####
##  ##  ##  ##  ##    ##  ##  ##  ##  ##  ##
#####   ##  ##  ##    ##  ##  ##   ####   #####

""" 
I might want to prevent accumulating speed from multiple explosions,
as it stands now the timing window is really rough to get a high jump from 2.
Just an awkward 'mechanic' right now.
"""

func hit_by_explosion(explosion_center:Vector3) -> void:
	# Check if bomb hit your shield
	var travel_vector = (self.head_position - explosion_center).normalized()
	var space_state = get_world().direct_space_state
	var result = space_state.intersect_ray(explosion_center, self.head_position, [], Layers.actor)
	if result.size() > 0:
		if result.shape > 0:
			# hit shield
			velocity += Player.forwards() * -14.0
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
	Player.lockplayer_for_frames(int(value))
	material.set_shader_param("damaged", true)
	hp -= value
	if hp <= 0:
		hp = 0
		die()
	Events.emit_signal('player_damaged')
	if shield.active:
		shield.put_away()
		
func die() -> void:
	#Events.emit_signal('player_died')
	respawn()

 ######   ##   #####   #####
## ## ##  ##  ##      ##
## ## ##  ##   ####   ##
##    ##  ##      ##  ##
##    ##  ##  #####    #####

func angle_to_flattened(a:Vector3, b:Vector3) -> float:
	# Flattens vector3 on the global y axis and returns rotational diff in signed radians
	return Vector2(a.x, a.z).angle_to(Vector2(b.x, b.z))


#####   #####  #####   ##  ##   #####
##  ##  ##     ##  ##  ##  ##  ## 
##  ##  ####   #####   ##  ##  ## ###
##  ##  ##     ##  ##  ##  ##  ##  ##
#####   #####  #####    ####    ####

func debug() -> void:
	# Debug Text
	Debug.text.write('Frame: ' + str(framecount))
	Debug.text.newline()
	
	Debug.text.write('Current Animation: ' + anim_state_machine.get_current_node())
	Debug.text.newline()
	
#	Debug.text.write('HP: ' + str(hp))
#	Debug.text.write('Subweapon: ' + str(current_subweapon))
#	Debug.text.write('Jewels: ' + str(jewels))
#	Debug.text.write('can_spawn_bomb()', 'green' if bombspawner.can_spawn_bomb() else 'red')
#	Debug.text.newline()
	Debug.text.write('Position: ' + str(transform.origin))
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
	Debug.text.write('Locked: ' + str(Player.lock_list), 'green' if Player.is_locked() else 'red')
	Debug.text.write('Grounded: ' + str(grounded), 'green' if grounded else 'red')
	Debug.text.write('Jump State: ' + str(jump_state))
	Debug.text.write('Jump Buffered: ' + str(!buffer_jump_timer.is_stopped()), 'green' if !buffer_jump_timer.is_stopped() else 'red')
	#Debug.text.write('Jumping: ' + str(jumping), 'green' if jumping else 'red')
	Debug.text.newline()
	Debug.text.write('Shielding: ' + str(shield.active), 'green' if shield.active else 'red')
	#Debug.text.write('Bashing: ' + str(shield.bash_str), 'green' if shield.bash_str > 0.0 else 'red')
	Debug.text.write('Sliding: ' + str(shield.sliding), 'green' if shield.sliding else 'red')
	Debug.text.newline()
	Debug.text.write('Sprinting: ' + str(sprint_count) + '/180')
	#Debug.text.write('Jumphold Framecount: ' + str(jumphold_framecount) + '/10')
	Debug.text.newline()
	Debug.text.write('Interactables: ' + str(interactables.list))
	Debug.text.newline()
	Debug.text.write("Collision Locations:")
	Debug.text.write(str(collision_locations))
	# Debug Draw
#	Debug.draw.begin(Mesh.PRIMITIVE_LINES)
#	Debug.draw.add_vertex(Game.player.head_position)
#	Debug.draw.add_vertex(Game.player.head_position + forwards())
#	Debug.draw.add_vertex(Game.player.head_position)
#	Debug.draw.add_vertex(Game.player.head_position + Vector3(velocity.x, 0, velocity.z).normalized())
#	Debug.draw.end()

