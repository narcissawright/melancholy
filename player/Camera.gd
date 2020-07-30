extends Camera

""" 
To Do:
	- release and repress ZL quickly to change target (maybe this is actually for the player code)
	- perhaps some context-sensitive rotation limits (such as looking from very low while targeting)
	
	- might also have a togglable option to auto-rotate the camera naturally based on your movement dir.
	- this option could also auto-rotate the camera to look from above when standing at an edge.
	- one other idea is to add camera 'whiskers' to avoid sudden 'crashing' into walls or floors etc.
	- perhaps all of those could be combined into the 'auto' mode, which could be turned off
"""

# Collision
var query := PhysicsShapeQueryParameters.new()
var shape := SphereShape.new()

# Position
var default_pos := Vector3(0, 0.316228, 0.948683) # default camera position, normalized
var current_pos:Vector3 # current camera position, normalized

# Zoom
var zoom_mode:String = 'medium'
var zoom_amt:float = 2.8
const zoom_lerp_amt:float = 0.2
const zoom_levels:Dictionary = {
		"near": 1.75,
		"medium": 2.9,
		"far": 4.1
	}

# Pan
var pause_pan := Vector3.ZERO # while paused, allow camera pan via d-pad
var pan_pos := Vector3.ZERO # camera may pan during ZL Targeting
const pan_lerp_amt:float = 0.08

# Joystick Movement
const move_speed:float = 0.04

# ZL Targeting
var multiple_targets:bool = false # True when ZL Target is an object
var zl_target_pos:Vector3 # might not need this as a "global" variable here.

# Camera Reset
var resetting:bool = false
const cam_reset_time:float = 16.0 # frames @ 60fps
var cam_reset_frame:float = 0.0   # stored as float to avoid integer division

func _ready() -> void:
	# Processing order: Player code should run first.
	process_priority = 1
	
	# Set up collision
	query.collide_with_areas = false
	query.collision_mask = Layers.solid
	shape.radius = 0.2
	query.set_shape(shape)
	
	# initialize the camera position
	update_cam_targets()
	update_position(default_pos) # Move into position

func update_cam_targets() -> void:
	# ZL Target Position
	if Game.player.zl_target == 0:
		multiple_targets = false
		zl_target_pos = Vector3.ZERO
	else:
		multiple_targets = true
		zl_target_pos = TargetSystem.list[Game.player.zl_target].pos

func screen_edge_detector(pos3d:Vector3) -> float:
	var pos2d:Vector2 = unproject_position(pos3d)
	var midpoint:Vector2 = OS.window_size / 2.0
	pos2d -= midpoint
	pos2d /= midpoint # Store this value more in terms of "percentage" rather than pixels.
	return abs(pos2d.x) + abs(pos2d.y) # these values may exceed 1 on each axis if offscreen

func _physics_process(_t:float) -> void:
	update_cam_targets()
	var pushdir:Vector2 = Game.get_stick_input("right")
	
	# Pause Mode / Panning
	var h_axis = current_pos.cross(Vector3.DOWN)
	var v_axis = h_axis.rotated(current_pos, PI/2.0)
	if get_tree().paused:
		if Input.is_action_pressed('d-up'):
			pause_pan += v_axis * move_speed
		if Input.is_action_pressed('d-down'):
			pause_pan -= v_axis * move_speed
		if Input.is_action_pressed('d-left'):
			pause_pan -= h_axis * move_speed
		if Input.is_action_pressed('d-right'):
			pause_pan += h_axis * move_speed
	else:
		pause_pan = Vector3.ZERO
	
	# If ZL Targeting an object:
	if multiple_targets:
		var player_amt:float = screen_edge_detector(Game.player.position)
		var target_amt:float = screen_edge_detector(zl_target_pos)
		
		player_amt = min(player_amt, 1.0)
		target_amt = min(target_amt, 1.0)
		
		var interpolate_amt:float = 0.5 - (player_amt / 2.0) + (target_amt / 2.0)
		var goal_target:Vector3 = Game.player.position.linear_interpolate(zl_target_pos, interpolate_amt)
		
		# Find goal_target distance from cam direction:
		# d is how far to move across the cam vector to reach the nearest position to goal_target
		var d:float = (goal_target - global_transform.origin).dot(-current_pos)
		# X is the new position on the cam direction vector line
		var X:Vector3 = global_transform.origin + -current_pos * d
		var goal_pan:Vector3 = (goal_target - X)
		pan_pos = pan_pos.linear_interpolate(goal_pan, pan_lerp_amt)
		
	# Not Multiple Targets
	else:
		if pan_pos != Vector3.ZERO:
			pan_pos = pan_pos.linear_interpolate(Vector3.ZERO, pan_lerp_amt)
			if pan_pos.length_squared() < 0.00001: pan_pos = Vector3.ZERO
		
	if Input.is_action_just_pressed('R3'):
		match zoom_mode:
			"medium": zoom_mode = 'near'
			"near": zoom_mode = 'far'
			"far": zoom_mode = 'medium'
	if zoom_amt != zoom_levels[zoom_mode]:
		zoom_amt = lerp(zoom_amt, zoom_levels[zoom_mode], zoom_lerp_amt)
		if abs(zoom_amt - zoom_levels[zoom_mode]) < 0.05:
			zoom_amt = zoom_levels[zoom_mode]
	
	if resetting:
		var goal_pos = default_pos.rotated(Vector3.UP, Game.player.rotation.y)
		if current_pos.is_equal_approx(goal_pos) or cam_reset_frame >= cam_reset_time:
			resetting = false
			cam_reset_frame = 0.0
			update_position(current_pos)
		else:
			cam_reset_frame += 1.0
			# new_y is the final y position in a normalized vec3
			var new_y = lerp(current_pos.y, goal_pos.y, cam_reset_frame / cam_reset_time)
			var xz = Vector2(current_pos.x, current_pos.z).normalized()
			var xz_goal = Vector2(goal_pos.x, goal_pos.z).normalized()
			xz = xz.slerp(xz_goal, cam_reset_frame / cam_reset_time) # horizontal rotation
			# need to multiply the xz values by a multiplier so new_pos is unit length
			xz *= sqrt(1 - new_y * new_y) # Thanks Syn and Eta
			var new_pos = Vector3(xz.x, new_y, xz.y) # should be ~unit length
			update_position(new_pos)
	
	elif pushdir.length_squared() > 0.0:
		var new_pos = current_pos
		var cross:Vector3 = new_pos.cross(Vector3.UP).normalized()
		new_pos = new_pos.rotated(Vector3.UP, -pushdir.x * move_speed)
		if (pushdir.y > 0.0 and new_pos.y > 0.0) or (pushdir.y < 0.0 and new_pos.y < 0.0):
			pushdir.y *= 1.0 - abs(new_pos.y)
		new_pos = new_pos.rotated(cross, pushdir.y * move_speed)
		new_pos.y = clamp(new_pos.y, -0.85, 0.85)
		update_position(new_pos)
	
	else:
		update_position(current_pos)
	
	# Write debug info
	Debug.text.write("Cam Position: " + str(self.global_transform.origin))
	Debug.text.write("Cam Relative Y-Pos: " + str(current_pos.y))
	Debug.text.write("Cam Zoom: " + str(zoom_amt) + " (" + zoom_mode + ")")
	Debug.text.write("Cam Pan: " + str(pan_pos + pause_pan))
	Debug.text.write("Cam Resetting: " + str(resetting), 'green' if resetting else 'red')
	Debug.text.write("Multiple Cam Targets: " + str(multiple_targets), 'green' if multiple_targets else 'red')
	Debug.text.newline()

func update_position(new_pos:Vector3) -> void:
	var cam_target = Game.player.position + pan_pos + pause_pan
	var space_state = get_world().direct_space_state # get the space.
	query.transform = Transform(Basis(), cam_target) # start at the cam_target
	new_pos *= zoom_amt # multiply by the current zoom value
	var result = space_state.cast_motion(query, new_pos) # until a collision happens
	if result[0] > 0: # result[0] is how much to lerp
		new_pos = cam_target.linear_interpolate(new_pos + cam_target, result[0]) # now we have final position
		look_at_from_position(new_pos, cam_target, Vector3.UP) # look at player from final position
	current_pos = (self.global_transform.origin - cam_target).normalized() # update current position
