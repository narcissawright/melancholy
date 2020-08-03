extends Camera

""" 
To Do:
	- autocamera peer over ledges
	- quick change target: 
		- release and repress ZL quickly to change target (maybe this is actually for the player code
	- first person view
	- code organization
	
Maybe:
	- perhaps some context-sensitive rotation limits (such as looking from very low while targeting)
	- pause mode improvements
		- tilt in pause mode.
		- smoother zoom in pause mode.
		- allow sliding the crosshair against surfaces.
		- a better boundary indicator
"""

# Collision
var query := PhysicsShapeQueryParameters.new()
var shape := SphereShape.new()

# Position
var default_pos := Vector3(0, 0.316228, 0.948683) # default camera position, normalized
var current_pos:Vector3 # current camera position, normalized

# Zoom
var zoom:float = 3.5
var default_zoom:float = 3.5
#const zoom_lerp_amt:float = 0.2
#var zoom_mode:String = 'medium'
#const zoom_levels:Dictionary = {
#		"near": 1.8,
#		"medium": 3.0,
#		"far": 4.2
#	}

var autocamera = true

# Pan
var pan:Vector3

# Pause Mode
var is_paused = false
var pause_pan_velocity := Vector3.ZERO # used for linear interpolation..


# WIP
# pressing ZL while paused should bring the cam to where it was when pause was initiated.
var saved_cam_state: Dictionary = {
	"cam_pos": Vector3.ZERO,
	"zoom": 0.0,
	"pan": Vector3.ZERO
} # do I need two pan values here?... I don't think so.


# Joystick Movement
const move_speed:float = 0.04

# ZL Targeting
var multiple_targets:bool = false # True when ZL Target is an object
var zl_target_pos:Vector3 # might not need this as a "global" variable here.
var zl_pan := Vector3.ZERO # camera may pan during ZL Targeting
const zl_pan_lerp_amt:float = 0.08

# Camera Reset
var resetting:bool = false
const cam_reset_time:float = 16.0 # frames @ 60fps
var cam_reset_frame:float = 0.0   # stored as float to avoid integer division

# Child nodes
#onready var crosshair = $Crosshair
onready var crosshair = $Crosshair

func _ready() -> void:
	
	Events.connect("pause", self, "_on_pause_state_change")
	crosshair.visible = false
	
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

func _on_pause_state_change(paused:bool) -> void:
	if paused:
		is_paused = true
		
		# Save State
		saved_cam_state.pos = current_pos
		saved_cam_state.pan = pan
		saved_cam_state.zoom = zoom
	else:
		crosshair.visible = false
		is_paused = false
		
		# Recover State
		pan = saved_cam_state.pan
		current_pos = saved_cam_state.pos
		zoom = saved_cam_state.zoom
		
		pause_pan_velocity = Vector3.ZERO

func pause_controls() -> void:
	
	if Input.is_action_just_pressed('ZL'):
		# This will bring the camera back to where it was when the pause was initiated
		pause_pan_velocity = Vector3.ZERO
		current_pos = saved_cam_state.pos
		pan = saved_cam_state.pan
		zoom = saved_cam_state.zoom
		crosshair.visible = false
	else:
		# Pan while paused
		# Find pan axes
		var h_axis = current_pos.cross(Vector3.DOWN)
		var v_axis = -h_axis.rotated(current_pos, PI/2.0)
		
		# Find pan velocity
		var pan_dir = Game.get_stick_input("left")
		var new_pan_velocity := Vector3.ZERO
		if pan_dir != Vector2.ZERO:
			new_pan_velocity = (pan_dir.x * h_axis) + (pan_dir.y * v_axis)
			new_pan_velocity *= 0.08
			crosshair.visible = true
		pause_pan_velocity = pause_pan_velocity.linear_interpolate(new_pan_velocity, 0.15)
		if pause_pan_velocity.is_equal_approx(Vector3.ZERO):
			crosshair.visible = false
		else:
			# If velocity isnt zero, perform collision detection
			var cam_target = Game.player.position + pan
			var space_state = get_world().direct_space_state
			shape.radius = 0.3
			query.transform = Transform(Basis(), cam_target)
			var result = space_state.cast_motion(query, pause_pan_velocity)
			pan += pause_pan_velocity * result[0]
		# If boundary has been reached, stop.
		if pan.length_squared() > 100.0: 
			pan = pan.normalized() * 10.0
		
		# Zoom while paused
		if Input.is_action_pressed("A"): zoom += 0.1
		if Input.is_action_pressed("X"): zoom -= 0.1
		zoom = clamp(zoom, 0.3, 10.0)

func multiple_targets() -> void:
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
	pan = pan.linear_interpolate(goal_pan, zl_pan_lerp_amt)

func zoom_change_unused() -> void:
	pass
	#	if Input.is_action_just_pressed('R3'):
#		match zoom_mode:
#			"medium": zoom_mode = 'near'
#			"near": zoom_mode = 'far'
#			"far": zoom_mode = 'medium'
#	if zoom_amt != zoom_levels[zoom_mode]:
#		zoom_amt = lerp(zoom_amt, zoom_levels[zoom_mode], zoom_lerp_amt)
#		if abs(zoom_amt - zoom_levels[zoom_mode]) < 0.05:
#			zoom_amt = zoom_levels[zoom_mode]
			
#	if Input.is_action_just_pressed('R3'):
#		zoom_amt = 0.0
#	if zoom_amt == 0.0: # 1st person
#		look_at_from_position(Game.player.position, Game.player.position + Game.player.forwards(), Vector3.UP)
#	else: # 3rd person

func camera_reset() -> void:
	var goal_pos = default_pos.rotated(Vector3.UP, Game.player.rotation.y)
	if current_pos.is_equal_approx(goal_pos) or cam_reset_frame >= cam_reset_time:
		resetting = false
		autocamera = true
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

func _physics_process(_t:float) -> void:
	update_cam_targets()
	#var pushdir:Vector2 = Game.get_stick_input("right")
	
	# Pause Mode / Panning
	if is_paused:
		pause_controls()
	# If ZL Targeting an object:
	elif multiple_targets:
		multiple_targets()
	# Not Multiple Targets
	else:
		if pan != Vector3.ZERO:
			pan = pan.linear_interpolate(Vector3.ZERO, zl_pan_lerp_amt)
			if pan.length_squared() < 0.00001: pan = Vector3.ZERO
	
	if resetting:
		camera_reset()
		return
	
	var rightstick = Game.get_stick_input("right")
	if rightstick.length_squared() > 0.0:
		autocamera = false
		var new_pos = current_pos
		var cross:Vector3 = new_pos.cross(Vector3.UP).normalized()
		
		# I want to prevent this from happening:
		if cross == Vector3.ZERO:
			print (current_pos) # (0, -1, 0)... so current position became totally vertical somehow.
			# need to check for it to prevent a crash.
			resetting = true
			
		if cross != Vector3.ZERO:
			new_pos = new_pos.rotated(Vector3.UP, -rightstick.x * move_speed)
			if (rightstick.y > 0.0 and new_pos.y > 0.0) or (rightstick.y < 0.0 and new_pos.y < 0.0):
				rightstick.y *= 1.0 - abs(new_pos.y)
			new_pos = new_pos.rotated(cross, rightstick.y * move_speed)
			new_pos.y = clamp(new_pos.y, -0.85, 0.85)
			update_position(new_pos)
		return
	
	if not is_paused and autocamera:
		if Game.player.grounded:
			var leftstick = Game.get_stick_input("left")
			var new_pos = current_pos
			var factor = max(abs(leftstick.x) - 0.25, 0.0) * 0.5
			var rotation_amount = -leftstick.x * move_speed * factor
			new_pos = new_pos.rotated(Vector3.UP, rotation_amount)
			update_position(new_pos)
			return
	
	update_position(current_pos)

func debug() -> void:
	# Write debug info
	Debug.text.write("Cam Pos: " + str(current_pos))
	Debug.text.write("Cam Zoom: " + str(zoom))
	Debug.text.write("Cam Pan: " + str(pan))
	Debug.text.write("Cam Target: " + str(Game.player.position + pan))
	Debug.text.write("Cam Resetting: " + str(resetting), 'green' if resetting else 'red')
	Debug.text.newline()

func update_position(new_pos:Vector3) -> void:
	var cam_target = Game.player.position + pan
	if is_paused:
		crosshair.global_transform = Transform(Basis(), cam_target)
	if zoom > 0.0:
		var space_state = get_world().direct_space_state # get the space.
		query.transform = Transform(Basis(), cam_target) # start at the cam_target
		shape.radius = 0.2
		new_pos *= zoom # multiply by the current zoom value
		var result = space_state.cast_motion(query, new_pos) # until a collision happens
		if result[0] > 0: # result[0] is how much to lerp
			new_pos = cam_target.linear_interpolate(new_pos + cam_target, result[0]) # now we have final position
			look_at_from_position(new_pos, cam_target, Vector3.UP) # look at player from final position
		current_pos = (self.global_transform.origin - cam_target).normalized() # update current position
