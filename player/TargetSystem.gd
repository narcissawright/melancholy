extends Node2D

var cursor_tex = load("res://img/target.png")
var list:Dictionary = {}
var highest_rel:Dictionary = {"relevance": 0.0 } # holds the priority target

const size := Vector2(15, 15) # cursor corner size, in pixels 
const half_size:int = 7 # rounded down
const upper_left_slice   := Rect2(Vector2(0, 0),      size) # how to slice up the cursor texture
const upper_right_slice  := Rect2(Vector2(size.x, 0), size)
const bottom_left_slice  := Rect2(Vector2(0, size.y), size)
const bottom_right_slice := Rect2(size,               size)

func _ready():
	process_priority = 2 # Run after camera

func get_most_relevant_target() -> Dictionary:
	if highest_rel.relevance > 0.0: return highest_rel
	else: return {}
	
func target_is_valid(target:Dictionary) -> bool:
	if target.empty():
		return true # Targeting nothing is valid
	
	for area in list:
		if list[area].hash() == target.hash():
			# Sorta dislike that I compare hashes here instead of using .has.
			# Unfortunately I am not passing the key but rather the value...
			# May need to rework this
			if not target.blocked and target.relevance > 0.0:
				return true
	
	# If the target passed does not exist in the target list, is it not valid.
	return false

func _physics_process(_t):
	
	# Manage Target List
	for area in list:
		var target = list[area]
		
		# Assign properties
		target.pos = target.parent.global_transform.origin
		target.aabb = target.parent.get_aabb()
		target.aabb2d = find_aabb_2d(target.pos, target.aabb)
		target.length = (target.pos - Game.player.translation).length()
		target.move_vector = -(Game.player.translation - target.pos).normalized()
		
		var window_size := Rect2(Vector2.ZERO, OS.window_size)
		
		# Check if object is blocked (behind camera, behind wall, etc)
		var ss:PhysicsDirectSpaceState = area.get_world().direct_space_state
		var result:Dictionary = ss.intersect_ray(Game.player.translation, area.global_transform.origin, [], Layers.solid)
		var blocked:bool = result.size() > 0 # If no line of sight, do not draw.
		if Game.cam.is_position_behind(target.pos): blocked = true # If behind camera, do not draw
		if not blocked:
			# Check if on camera
			window_size = window_size.grow(half_size) # always draw the partial graphic @ screen edge
			blocked = true # Assumed blocked unless any of the corners are on screen
			if   window_size.has_point(Vector2(target.aabb2d.position.x, target.aabb2d.position.y)): blocked = false
			elif window_size.has_point(Vector2(target.aabb2d.end.x,      target.aabb2d.position.y)): blocked = false
			elif window_size.has_point(Vector2(target.aabb2d.position.x, target.aabb2d.end.y)):      blocked = false
			elif window_size.has_point(Vector2(target.aabb2d.end.x,      target.aabb2d.end.y)):      blocked = false
			
		target.blocked = blocked # Assign blocked
		target.relevance = 0.0
		
		if not blocked: # Assign relevance (for targeting priority)
			
			# The closer the target is to the middle of the screen, the higher relevance it has
			var target_pos_2d:Vector2 = Game.cam.unproject_position(target.pos)
			var midscreen:Vector2 = OS.window_size / 2.0
			var rel_center_screen:float = max(1.0 - (midscreen - target_pos_2d).length() / (midscreen.length()), 0.0)
			
			# The closer the target is to the player, the higher relevance it has
			var rel_nearby_player:float = 1.0 - (target.length / 20.0)
			
			# The closer the target is to the player facing direction, the higher relevance it has
			var rel_player_facing:float = 0.0
			var playerfacedir = Game.player.forwards()
			var starting_point = Game.player.translation
			# Height will be ignored for this calculation
			starting_point.y = 0.0
			var target_pos_no_height = target.pos
			target_pos_no_height.y = 0.0
			# d is how far to move across the playerfacedir vector to reach the nearest position to target_pos_no_height
			var d = (target_pos_no_height - starting_point).dot(playerfacedir)
			if d > 0.0:
				# X is the new position on the playerfacedir line
				var X = starting_point + playerfacedir * d
				var dist = (target_pos_no_height - X).length()
				rel_player_facing = max(1.0 - (dist / 10.0), 0.0)
			else:
				rel_player_facing = 0.0
			
			# Combine all 3 factors
			target.relevance = (rel_center_screen + rel_nearby_player + rel_player_facing) / 3.0
	
	highest_rel = {"relevance": 0.0}
	# find which target has highest relevance
	for area in list:
		if not list[area].blocked:
			if list[area].relevance > highest_rel.relevance:
				highest_rel = list[area]
	
	Game.debug.text.write('Target list:')
	for area in list:
		var target = list[area]
		Game.debug.text.write(target.name + ' | Rel: ' + str(target.relevance), 'red' if target.blocked else 'blue')
	Game.debug.text.newline()
	
	update()

func find_aabb_2d(target_pos:Vector3, aabb:AABB) -> Rect2:
	# a list of the 8 vertices that make up the axis aligned bounding box assigned to this target
	var points := [
		target_pos + aabb.position,
		target_pos + aabb.position + Vector3(aabb.size.x, 0, 0),
		target_pos + aabb.position + Vector3(0, aabb.size.y, 0),
		target_pos + aabb.position + Vector3(0, 0, aabb.size.z),
		target_pos + aabb.position + Vector3(aabb.size.x, aabb.size.y, aabb.size.z),
		target_pos + aabb.position + Vector3(0, aabb.size.y, aabb.size.z),
		target_pos + aabb.position + Vector3(aabb.size.x, 0, aabb.size.z),
		target_pos + aabb.position + Vector3(aabb.size.x, aabb.size.y, 0)
	]
	
	# find the 2d viewport position of all 8 bounding box vertices
	for j in range (points.size()):
		points[j] = Game.cam.unproject_position(points[j])
		
	# sort the eight 2d points by their x position
	var x_sort = []
	for j in range (points.size()):
		x_sort.append(points[j].x)
	x_sort.sort()
	
	# sort by y position
	var y_sort = []
	for j in range (points.size()):
		y_sort.append(points[j].y)
	y_sort.sort()
	
	# take the 3 points closest to an edge, and average their position
	# do this for all 4 sides
	var x_min = (x_sort[0] + x_sort[1] + x_sort[2]) / 3.0
	var x_max = (x_sort[5] + x_sort[6] + x_sort[7]) / 3.0
	var y_min = (y_sort[0] + y_sort[1] + y_sort[2]) / 3.0
	var y_max = (y_sort[5] + y_sort[6] + y_sort[7]) / 3.0
	
	return Rect2(x_min, y_min, x_max-x_min, y_max-y_min)

func _draw(): # update called in player
	for area in list:
		var target = list[area]
		
		if target.blocked:
			continue # if no direct line of sight to the target, do not draw crosshair
			
		var distance:float = (Game.cam.global_transform.origin - target.pos).length()
		var opacity:float = 1.0
		opacity = clamp(distance - 1.5, 0.0, 1.0)
#		opacity = 1.0 - clamp((distance - 15.0) / 5.0, 0.0, 1.0)
		
		var color = Color(0.4, 0.4, 0.4, opacity) # grey
		if highest_rel.hash() == target.hash():
			color = Color(0.66, 0.75, 0.0, opacity) # yellow
		if target.hash() == Game.player.zl_target.hash():
			color = Color(1.0, 0.1, 0.1, opacity) # red
			
		#if target_list[i].seeking:
		#	color = Color(1, 0.2, 0.15, opacity) # red
		
		# where to draw the cursor corners:
		var upper_left_pos   = Rect2(Vector2(target.aabb2d.position.x - half_size, target.aabb2d.position.y - half_size), size)
		var upper_right_pos  = Rect2(Vector2(target.aabb2d.end.x - half_size, target.aabb2d.position.y - half_size), size)
		var bottom_left_pos  = Rect2(Vector2(target.aabb2d.position.x - half_size, target.aabb2d.end.y - half_size), size)
		var bottom_right_pos = Rect2(Vector2(target.aabb2d.end.x - half_size, target.aabb2d.end.y - half_size), size)
		
		# draw
		draw_texture_rect_region(cursor_tex, upper_left_pos,   upper_left_slice,   color)
		draw_texture_rect_region(cursor_tex, upper_right_pos,  upper_right_slice,  color)
		draw_texture_rect_region(cursor_tex, bottom_left_pos,  bottom_left_slice,  color)
		draw_texture_rect_region(cursor_tex, bottom_right_pos, bottom_right_slice, color)

# Signals
func _target_acquired(area: Area) -> void:
	var parent = area.get_parent()
	# More properties assigned and updated when managing the target list elsewhere
	# These ones are static so I can assign them here and never again.
	list[area] = {
		"parent": parent,
		"name": parent.name
	}
func _target_lost(area: Area) -> void:
	list.erase(area)
