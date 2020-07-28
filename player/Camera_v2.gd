extends Camera

# Collision
var shape := PhysicsShapeQueryParameters.new()
var cam_collider := SphereShape.new()

# Position
var default_pos := Vector3(0, 0.316228, 0.948683) # default camera position, normalized
var current_pos:Vector3 # current camera position, normalized
var cam_target_pos:Vector3 # camera target position, world space (not to be confused with ZL Targeting)
var pan_pos := Vector3.ZERO # while paused, allow camera pan via d-pad

# Camera Movement
const move_speed:float = 0.04

# ZL Targeting
var multiple_targets:bool = false # True when ZL Target is an object
var resetting:bool = false
const cam_reset_time:float = 16.0 # frames @ 60fps
var cam_reset_frame:float = 0.0   # stored as float to avoid integer division

# Camera Zoom
var current_zoom_type:String = 'medium'
var current_zoom_value:float = 2.8
const zoom_levels:Dictionary = {
		"near": 1.75,
		"medium": 2.9,
		"far": 4.1
	}

# To do...
# - nice curve to avoid crashing into floor
# - maybe aim a bit in the dir player is lookin or moving?
# - look down a bit when standing at edge

func _ready() -> void:
	# Processing order: Player code should run first.
	process_priority = 1
	
	# Set up collision
	shape.collide_with_areas = false
	shape.collision_mask = Layers.solid
	cam_collider.radius = 0.2
	shape.set_shape(cam_collider)
	
	# initialize the camera position
	update_cam_target()
	update_position(default_pos) # Move into position

func update_cam_target() -> void:
	# I may need to rewrite this to include multiple targets.
	# I don't think I ever need to focus on more than two targets
	# Those being the player and the ZL target.
	# It's plausible I could include other ones though
	
	var player_height_offset := Vector3(0, 1.25, 0)
	cam_target_pos = Game.player.global_transform.origin + player_height_offset + pan_pos
	if not Game.player.zl_target.empty():
		pass

func _physics_process(_t:float) -> void:
	update_cam_target()
	var pushdir:Vector2 = Game.get_stick_input("right")
	
	# Panning
	if get_tree().paused:
		var h_axis = current_pos.cross(Vector3.DOWN)
		var v_axis = h_axis.rotated(current_pos, PI/2.0)
		if Input.is_action_pressed('d-up'):
			pan_pos += v_axis * move_speed
		if Input.is_action_pressed('d-down'):
			pan_pos -= v_axis * move_speed
		if Input.is_action_pressed('d-left'):
			pan_pos -= h_axis * move_speed
		if Input.is_action_pressed('d-right'):
			pan_pos += h_axis * move_speed
	else:
		pan_pos = Vector3.ZERO
	
	# Camera Zoom
	if Input.is_action_just_pressed('R3'):
		match current_zoom_type:
			"medium":
				current_zoom_type = 'near'
			"near":
				current_zoom_type = 'far'
			"far":
				current_zoom_type = 'medium'
	if current_zoom_value != zoom_levels[current_zoom_type]:
		current_zoom_value = lerp(current_zoom_value, zoom_levels[current_zoom_type], 0.33)
		if abs(current_zoom_value - zoom_levels[current_zoom_type]) < 0.05:
			current_zoom_value = zoom_levels[current_zoom_type]
	
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
	Game.debug.text.write("Cam Position: " + str(self.global_transform.origin))
	Game.debug.text.write("Cam Relative Y-Pos: " + str(current_pos.y))
	Game.debug.text.write("Cam Resetting: " + str(resetting), 'green' if resetting else 'red')
	Game.debug.text.write("Cam Zoom: " + str(current_zoom_value) + " (" + current_zoom_type + ")")
	Game.debug.text.newline()

func update_position(new_pos:Vector3) -> void:
	var space_state = get_world().direct_space_state # get the space.
	shape.transform = Transform(Basis(), cam_target_pos) # start at the player,
	new_pos *= current_zoom_value
	var result = space_state.cast_motion(shape, new_pos) # until a collision happens
	if result[0] > 0: # result[0] is how much to lerp
		new_pos = cam_target_pos.linear_interpolate(new_pos + cam_target_pos, result[0]) # now we have final position
		look_at_from_position(new_pos, cam_target_pos, Vector3.UP) # look at player from final position
	current_pos = (self.global_transform.origin - cam_target_pos).normalized() # update current position
