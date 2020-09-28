extends Node

""" 
This file right now is an absolute disaster
although it does provide a good look at ALL external calls to Player
sort of like an API to interact with the player.

The generic stuff that isn't specific to Melanie should be moved into this script.
"""

var frame_time:float = 1.0 / 60.0
var character:String = "Melanie"
var kinematicbody:KinematicBody
onready var Melanie = $Melanie
onready var Melancholy = $Melancholy
onready var TargetSystem = $TargetSystem

func _ready() -> void:
	match character:
		"Melanie":    kinematicbody = Melanie
		"Melancholy": kinematicbody = Melancholy
			
	kinematicbody.initialize()
			
	shield = kinematicbody.shield
	anim_tree = kinematicbody.anim_tree
	bombspawner = Melanie.bombspawner # melancholy should have this too, fix later
	max_hp = kinematicbody.max_hp

func _physics_process(t:float) -> void:
	kinematicbody.process_frame(t)


# FIRST PERSON
# called from MainCam

func enter_first_person() -> void:
	if shield.active:
		shield.put_away()
	if bombspawner.holding:
		bombspawner.drop_bomb()
	untarget()
	lockplayer("first_person")

func exit_first_person() -> void:
	safe_look_at(-MainCam.current_pos)
	unlockplayer("first_person")

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
	kinematicbody.material.set_shader_param("locked", true)

func _on_LockPlayer_timeout() -> void:
	unlockplayer("timer")
	
func unlockplayer(reason) -> void:
	lock_list.erase(reason)
	if not is_locked():
		kinematicbody.material.set_shader_param("locked", false)
		kinematicbody.material.set_shader_param("damaged", false)


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
	var pushdir:Vector2 = get_stick_input("left")
	var camdir:Vector3 = MainCam.global_transform.basis.z
	camdir.y = 0.0
	camdir = camdir.normalized()
	return (camdir * pushdir.y) + (camdir.rotated(Vector3.UP, PI/2) * pushdir.x)

#####    ####   ######   ####   ######  ##   ####   ##  ##
##  ##  ##  ##    ##    ##  ##    ##    ##  ##  ##  ### ##
#####   ##  ##    ##    ######    ##    ##  ##  ##  ######
##  ##  ##  ##    ##    ##  ##    ##    ##  ##  ##  ## ###
##  ##   ####     ##    ##  ##    ##    ##   ####   ##  ##

var look_target := Vector3.ZERO # used for Rotation

func forwards() -> Vector3:
	return -kinematicbody.global_transform.basis.z

func handle_player_rotation() -> void:
	#print (Player.is_locked(), MainCam.mode, look_target)
	
	if is_locked() or not self.grounded:
		return

	look_target = look_target.linear_interpolate(find_movement_direction(), 0.15)
	
	# While not targeting: Look towards movement direction
	if not self.targeting:
		var look_target_2d = Vector2(look_target.x, look_target.z).normalized()
		if not look_target_2d.is_equal_approx(Vector2.ZERO): # If not moving, don't rotate
			rotate_towards(look_target_2d)

	# While targeting -- look towards target
	elif self.targeting and self.zl_target != 0:
		var look_target_2d := Vector2(self.position.x, self.position.z)
		look_target_2d -= Vector2(TargetSystem.list[self.zl_target].pos.x, TargetSystem.list[self.zl_target].pos.z)
		look_target_2d = -look_target_2d.normalized()
		rotate_towards(look_target_2d)

func rotate_towards(look_target_2d:Vector2) -> void:
	# find the amount of radians needed to face target direction
	var angle = -Vector2(forwards().x, forwards().z).angle_to(look_target_2d)
	
	# Takes in a rotation amount in radians, and clamps it to the maximum allowed rotation amount
	if shield.active: angle = clamp(angle, -PI/80.0, PI/80.0)  # Slow rotation while shielding
	else:             angle = clamp(angle, -PI/8.0,  PI/8.0)   # Fast rotation while not shielding
	
	# If you are not targeting, have the rotation amount be very small when moving slowly
	if not self.targeting: angle *= clamp(Vector3(self.velocity.x, 0, self.velocity.z).length_squared(), 0.0, 1.0)
	
	# If angle is close to 0, don't bother
	if not is_equal_approx(angle, 0.0):
		var lookdir:Vector3 = forwards().rotated(Vector3.UP, angle)
		safe_look_at(lookdir)

# safe rotation, removed y component so the body will never skew weirdly.
# this could also involve head rotation later.
func safe_look_at(lookdir:Vector3) -> void:
	lookdir.y = 0.0 
	lookdir = lookdir.normalized()
	if lookdir.is_equal_approx(Vector3.ZERO): return
	kinematicbody.look_at(lookdir + self.position, Vector3.UP)
	print (lookdir)






# TODO: CLEAN UP

var position:Vector3 setget set_position, get_position
func set_position(pos:Vector3) -> void:
	kinematicbody.global_transform.origin = pos
func get_position() -> Vector3:
	return kinematicbody.global_transform.origin

# test_enemy.gd, Camera.gd
var head_position setget , get_head_position
func get_head_position() -> Vector3:
	return kinematicbody.head_position

var ledgegrabbing setget , get_ledgegrabbing
func get_ledgegrabbing() -> bool:
	return kinematicbody.ledgegrabbing

var jewels:int setget set_jewels, get_jewels
func set_jewels(value:int) -> void:
	kinematicbody.jewels = value
func get_jewels() -> int:
	return kinematicbody.jewels
	
var max_jewels:int = 999
var shield
var anim_tree
var bombspawner
var max_hp:float
	
var hp:float setget set_hp, get_hp
func set_hp(value:float) -> void:
	kinematicbody.hp = value
func get_hp() -> float:
	return kinematicbody.hp
	
var grounded:bool setget , get_grounded
func get_grounded() -> bool:
	return kinematicbody.grounded
	
func untarget() -> void:
	kinematicbody.untarget()

func obtain_item(what:String) -> void:
	kinematicbody.obtain_item(what)

var current_subweapon:String setget set_current_subweapon, get_current_subweapon
func set_current_subweapon(subweapon:String) -> void:
	kinematicbody.current_subweapon = subweapon
func get_current_subweapon() -> String:
	return kinematicbody.current_subweapon

var inventory:Array setget , get_inventory
func get_inventory() -> Array:
	return kinematicbody.inventory

func inventory_is_full() -> bool:
	return kinematicbody.inventory_is_full()

func set_geometry_aabb(aabb:AABB) -> void:
	kinematicbody.set_geometry_aabb(aabb)

var velocity:Vector3 setget set_velocity, get_velocity
func set_velocity(value:Vector3):
	kinematicbody.velocity = value 
func get_velocity() -> Vector3:
	return kinematicbody.velocity
	
var rotation:Vector3 setget , get_rotation
func get_rotation() -> Vector3:
	return kinematicbody.rotation

var zl_target:int setget set_zl_target, get_zl_target
func set_zl_target(target:int) -> void:
	kinematicbody.zl_target = target 
func get_zl_target() -> int:
	return kinematicbody.zl_target

func horizontal_velocity() -> Vector3:
	return kinematicbody.horizontal_velocity()
	
var targeting:bool setget set_targeting, get_targeting
func set_targeting(state:bool) -> void:
	kinematicbody.targeting = state
func get_targeting() -> bool:
	return kinematicbody.targeting

var xform:Transform setget , get_xform
func get_xform() -> Transform:
	return kinematicbody.global_transform


