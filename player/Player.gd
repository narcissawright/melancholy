extends Node

""" 
This file right now is an absolute disaster
although it does provide a good look at ALL external calls to Player
sort of like an API to interact with the player.

The generic stuff that isn't specific to Melanie should be moved into this script.
"""

var character:String = "Melanie"
var kinematicbody:KinematicBody
onready var Melanie = $Melanie
onready var Melancholy = $Melancholy
onready var TargetSystem = $TargetSystem

func _ready() -> void:
	
	match character:
		"Melanie":
			Melanie.set_physics_process(true)
			kinematicbody = Melanie
			Melanie.visible = true
		"Melancholy":
			Melancholy.set_physics_process(true)
			kinematicbody = Melancholy
			Melancholy.visible = true
			
	shield = kinematicbody.shield
	anim_tree = kinematicbody.anim_tree
	bombspawner = Melanie.bombspawner
	max_hp = kinematicbody.max_hp

var position:Vector3 setget set_position, get_position
func set_position(pos:Vector3) -> void:
	kinematicbody.global_transform.origin = pos
func get_position() -> Vector3:
	return kinematicbody.global_transform.origin

var forwards:Vector3 setget , get_forwards
func get_forwards() -> Vector3:
	return -kinematicbody.global_transform.basis.z

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
	
var visible:bool setget set_visible
func set_visible(value:bool) -> void:
	kinematicbody.visible = value
	
func safe_look_at(pos:Vector3) -> void:
	kinematicbody.safe_look_at(pos)
	
func untarget() -> void:
	kinematicbody.untarget()

func obtain_item(what:String) -> void:
	kinematicbody.obtain_item(what)

func lockplayer(reason:String) -> void:
	kinematicbody.lockplayer(reason)
	
func unlockplayer(reason:String) -> void:
	kinematicbody.unlockplayer(reason)

func lockplayer_for_frames(frames:int) -> void:
	kinematicbody.lockplayer_for_frames(frames)

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

func is_locked() -> bool:
	return kinematicbody.is_locked()

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
