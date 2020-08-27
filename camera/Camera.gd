extends Camera

# Collision
var query := PhysicsShapeQueryParameters.new()
var shape := SphereShape.new()

# Position
var default_pos := Vector3(0, 0.316228, 0.948683) # default camera position, normalized
var current_pos:Vector3 # current camera position, normalized

# Zoom
var current_zoom:float = 3.2
var custom_zoom:float = 3.2

var mode = "auto" # "free", "first_person", "pause", "reset"
var pause_controls_enabled = false

# Pan
var pan:Vector3
var pause_pan_velocity := Vector3.ZERO # used for linear interpolation..

# State of the camera when pause was initiated
var saved_cam_state: Dictionary = {
	"cam_pos": Vector3.ZERO,
	"zoom": 0.0,
	"pan": Vector3.ZERO,
	"mode": "auto"
}

# Joystick Movement
const move_speed:float = 0.04

# Camera Reset
const cam_reset_time:float = 16.0 # frames @ 60fps
var cam_reset_frame:float = 0.0   # stored as float to avoid integer division

# Child nodes
onready var crosshair = $Crosshair
onready var zoom_tween = $ZoomTween

func _ready() -> void:
	Events.connect("player_damaged", self, "_on_player_damaged")
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
	current_pos = default_pos
	update_position() # Move into position

func _on_player_damaged() -> void:
	if mode == "first_person":
		exit_first_person()

func update_position() -> void:
	var cam_target = Game.player.head_position + pan
	if mode == "pause":
		crosshair.global_transform = Transform(Basis(), cam_target)
	var space_state = get_world().direct_space_state # get the space.
	query.transform = Transform(Basis(), cam_target) # start at the cam_target
	shape.radius = 0.2
	var new_pos = current_pos * current_zoom
	var result = space_state.cast_motion(query, new_pos) # until a collision happens
	if result[0] > 0: # result[0] is how much to lerp
		new_pos = cam_target.linear_interpolate(new_pos + cam_target, result[0]) # now we have final position
		look_at_from_position(new_pos, cam_target, Vector3.UP) # look at player from final position
	current_pos = (self.global_transform.origin - cam_target).normalized() # update current position
	if mode == "first_person":
		var lookdir = Vector3(-current_pos.x, 0, -current_pos.z)
		Game.player.look_at(lookdir + Game.player.global_transform.origin, Vector3.UP)

func _on_pause_state_change(paused:bool) -> void:
	if paused:
		# Save State
		zoom_tween.stop_all()
		saved_cam_state.pos = current_pos
		saved_cam_state.pan = pan
		saved_cam_state.zoom = current_zoom
		saved_cam_state.mode = mode
		mode = "pause"
	else:
		zoom_tween.resume_all()
		crosshair.visible = false
		pause_pan_velocity = Vector3.ZERO
		pause_controls_enabled = false
		# Recover State
		pan = saved_cam_state.pan
		current_pos = saved_cam_state.pos
		current_zoom = saved_cam_state.zoom
		mode = saved_cam_state.mode
		
func _physics_process(_t:float) -> void:
	#debug()
		
	match mode:
		"pause":
			pause_controls()
		"first_person":
			first_person()
		"reset":
			camera_reset()
		"auto":
			if Input.is_action_just_pressed("R3"):
				if can_enter_first_person():
					enter_first_person()
					return
			update_zl_target_pan()
			auto_mode()
		"free":
			if Input.is_action_just_pressed("R3"):
				if can_enter_first_person():
					enter_first_person()
					return
			update_zl_target_pan()
			free_mode()
			
func free_mode() -> void:
	var rightstick = Game.get_stick_input("right")
	rotate_cam(rightstick)
	update_position()

func auto_mode() -> void:
	# Autocamera
	var rightstick = Game.get_stick_input("right")
	if rightstick.length_squared() > 0.0:
		mode = "free"
		free_mode()
		return
	
	if not Game.player.targeting:
		var hvelocity = Game.player.horizontal_velocity()
		var movedir := Vector2(hvelocity.x, hvelocity.z)
		var x_movement = -movedir.rotated(rotation.y).x
		x_movement = clamp(x_movement / 10.0, -1.0, 1.0)
		var factor = max(abs(x_movement) - 0.20, 0.0) * 0.02
		var rotation_amount = x_movement * factor
		current_pos = current_pos.rotated(Vector3.UP, rotation_amount)
	
	update_position()

func rotate_cam(dir:Vector2) -> void:
	var new_pos = current_pos
	var cross:Vector3 = new_pos.cross(Vector3.UP).normalized()
	if cross != Vector3.ZERO:
		var move_speed = 0.04
		new_pos = new_pos.rotated(Vector3.UP, -dir.x * move_speed)
		if (dir.y > 0.0 and new_pos.y > 0.0) or (dir.y < 0.0 and new_pos.y < 0.0):
			dir.y *= 1.0 - abs(new_pos.y)
		new_pos = new_pos.rotated(cross, dir.y * move_speed)
		new_pos.y = clamp(new_pos.y, -0.85, 0.85)
		current_pos = new_pos

func enable_pause_controls() -> void:
	pause_controls_enabled = true

func reset_pause_cam_state() -> void:
	pause_pan_velocity = Vector3.ZERO
	current_pos = saved_cam_state.pos
	pan = saved_cam_state.pan
	current_zoom = saved_cam_state.zoom
	crosshair.visible = false

func pause_controls() -> void:
	if not pause_controls_enabled:
		return
	
	if Input.is_action_just_pressed('B'):
		# Cancel button
		pause_controls_enabled = false
		reset_pause_cam_state()
		Game.ui.paused.exit_free_camera()
	
	elif Input.is_action_just_pressed('L'):
		# This will bring the camera back to where it was when the pause was initiated
		reset_pause_cam_state()
		
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
			var cam_target = Game.player.head_position + pan
			var space_state = get_world().direct_space_state
			shape.radius = 0.3
			query.transform = Transform(Basis(), cam_target)
			var result = space_state.cast_motion(query, pause_pan_velocity)
			pan += pause_pan_velocity * result[0]
		# If boundary has been reached, stop.
		if pan.length_squared() > 100.0: 
			pan = pan.normalized() * 10.0
		
		# Zoom while paused
		if Input.is_action_pressed("ZL"): current_zoom += 0.1
		if Input.is_action_pressed("ZR"): current_zoom -= 0.1
		current_zoom = clamp(current_zoom, 0.3, 10.0)
		
		# Rotate while paused
		var rightstick = Game.get_stick_input("right")
		if rightstick.length_squared() > 0.0:
			rotate_cam(rightstick)
	
	update_position()

func update_zl_target_pan() -> void:
	
	var zl_pan_lerp_amt = 0.08
	
	if Game.player.zl_target == 0:
		if pan != Vector3.ZERO:
			pan = pan.linear_interpolate(Vector3.ZERO, zl_pan_lerp_amt)
		if pan.length_squared() < 0.00001: pan = Vector3.ZERO
	else:
		var zl_target_pos:Vector3 = TargetSystem.list[Game.player.zl_target].pos
	
		var player_amt:float = screen_edge_detector(Game.player.head_position)
		var target_amt:float = screen_edge_detector(zl_target_pos)
		
		player_amt = min(player_amt, 1.0)
		target_amt = min(target_amt, 1.0)
		
		var interpolate_amt:float = 0.5 - (player_amt / 2.0) + (target_amt / 2.0)
		var goal_target:Vector3 = Game.player.head_position.linear_interpolate(zl_target_pos, interpolate_amt)
		
		# Find goal_target distance from cam direction:
		# d is how far to move across the cam vector to reach the nearest position to goal_target
		var d:float = (goal_target - global_transform.origin).dot(-current_pos)
		# X is the new position on the cam direction vector line
		var X:Vector3 = global_transform.origin + -current_pos * d
		var goal_pan:Vector3 = (goal_target - X)
		pan = pan.linear_interpolate(goal_pan, zl_pan_lerp_amt)

func screen_edge_detector(pos3d:Vector3) -> float:
	var pos2d:Vector2 = unproject_position(pos3d)
	var midpoint:Vector2 = OS.window_size / 2.0
	pos2d -= midpoint
	pos2d /= midpoint # Store this value more in terms of "percentage" rather than pixels.
	return abs(pos2d.x) + abs(pos2d.y) # these values may exceed 1 on each axis if offscreen

func reset() -> void:
	if mode != "first_person":
		mode = "reset"

func camera_reset() -> void:
	var goal_pos = default_pos.rotated(Vector3.UP, Game.player.rotation.y)
	if current_pos.is_equal_approx(goal_pos) or cam_reset_frame >= cam_reset_time:
		mode = "auto"
		cam_reset_frame = 0.0
		update_position()
	else:
		cam_reset_frame += 1.0
		# new_y is the final y position in a normalized vec3
		var new_y = lerp(current_pos.y, goal_pos.y, cam_reset_frame / cam_reset_time)
		var xz = Vector2(current_pos.x, current_pos.z).normalized()
		var xz_goal = Vector2(goal_pos.x, goal_pos.z).normalized()
		xz = xz.slerp(xz_goal, cam_reset_frame / cam_reset_time) # horizontal rotation
		# need to multiply the xz values by a multiplier so new_pos is unit length
		xz *= sqrt(1.0 - new_y * new_y) # Thanks Syn and Eta
		current_pos = Vector3(xz.x, new_y, xz.y) # should be ~unit length
		update_position()

func can_enter_first_person() -> bool:
	if Game.player.grounded and not Game.player.is_locked():
		return true
	return false

func enter_first_person() -> void:
	mode = "first_person"
	zoom_tween.interpolate_property(self, "current_zoom", current_zoom, 0.01, 0.15)
	zoom_tween.interpolate_property(self, "pan", pan, Vector3.ZERO, 0.15)
	zoom_tween.start()
	if Game.player.shield.active:
		Game.player.shield.put_away()
	if Game.player.bombspawner.holding:
		Game.player.bombspawner.drop_bomb()
	current_pos = -Game.player.forwards()
	Game.player.untarget()
	Game.player.lockplayer("first_person")

func first_person() -> void:
	var exiting = false
	if not Game.player.grounded: exiting = true
	if Input.is_action_just_pressed("A"): exiting = true
	elif Input.is_action_just_pressed("B"): exiting = true
	elif Input.is_action_just_pressed("X"): exiting = true
	elif Input.is_action_just_pressed("Y"): exiting = true
	elif Input.is_action_just_pressed("R3"): exiting = true
	if exiting: exit_first_person()
	else:
		var dir = Game.get_stick_input("left")
		if dir.length_squared() > 0.0:
			rotate_cam(dir)
		else:
			dir = Game.get_stick_input("right")
			if dir.length_squared() > 0.0:
				rotate_cam(dir)
		update_position()

func exit_first_person() -> void:
	Game.player.unlockplayer("first_person")
	zoom_tween.interpolate_property(self, "current_zoom", current_zoom, custom_zoom, 0.15)
	zoom_tween.start()
	mode = "auto"
	current_pos = default_pos.rotated(Vector3.UP, Game.player.rotation.y)
	Game.player.visible = true

func _on_ZoomTween_tween_completed(_object: Object, _key: NodePath) -> void:
	if mode == "first_person":
		Game.player.visible = false

func debug() -> void:
	# Write debug info
	Debug.text.write("Cam Mode: " + mode)
	Debug.text.write("Cam Pos: " + str(current_pos))
	Debug.text.write("Cam Zoom: " + str(current_zoom))
	Debug.text.write("Cam Pan: " + str(pan))
	Debug.text.write("Cam Reset: " + str(cam_reset_frame))
	Debug.text.newline()
	
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
#		look_at_from_position(Game.player.head_position, Game.player.head_position + Game.player.forwards(), Vector3.UP)
#	else: # 3rd person


