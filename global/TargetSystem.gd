extends Node2D

var cursor_tex = load("res://img/target.png")
var list:Dictionary = {}
var highest_rel:int = 0 # holds the priority target
var paused # is the game paused

const size := Vector2(15, 15) # cursor corner size, in pixels 
const half_corner_size:int = 7 # rounded down
const upper_left_slice   := Rect2(Vector2(0, 0),      size) # how to slice up the cursor texture
const upper_right_slice  := Rect2(Vector2(size.x, 0), size)
const bottom_left_slice  := Rect2(Vector2(0, size.y), size)
const bottom_right_slice := Rect2(size,               size)

func _ready():
	process_priority = 2 # Run after camera
	pause_mode = PAUSE_MODE_PROCESS
	Events.connect('pause', self, "_on_pause_state_change")

func _on_pause_state_change(state) -> void:
	paused = state

func get_most_relevant_target() -> int:
	if highest_rel == 0: return 0
	elif list[highest_rel].relevance > 0.0: return highest_rel
	else: return 0

func target_is_valid(target:int) -> bool:
	if target == 0:
		return true # Targeting nothing is valid
	
	for id in list:
		if id == target:
			if list[target].relevance > 0.0:
				return true
	
	# If the target passed does not exist in the target list, is it not valid.
	return false

func _physics_process(_t) -> void:
	if paused:
		manage_target_list_paused()
	else:
		manage_target_list()
		
	debug()
	update()

func manage_target_list_paused() -> void:
	for id in list:
		var target = list[id]
		target.aabb2d = find_aabb_2d(target.pos, target.aabb) 
		target.on_cam = is_target_on_camera(target)

func manage_target_list() -> void:
	for id in list:
		var target = list[id]
		
		# Assign properties
		target.pos = target.parent.global_transform.origin
		target.length = (target.pos - Game.player.translation).length()
		target.move_vector = -(Game.player.translation - target.pos).normalized()
		target.aabb2d = find_aabb_2d(target.pos, target.aabb) 
		target.on_cam = is_target_on_camera(target)
		
		# Check for player line of sight
		var ss:PhysicsDirectSpaceState = target.area.get_world().direct_space_state
		var result:Dictionary = ss.intersect_ray(Game.player.translation, target.area.global_transform.origin, [], Layers.solid)
		var blocked = result.size() > 0 # If no line of sight, do not draw.
		
		target.relevance = 0.0
		if not blocked and target.on_cam: # Assign relevance (for targeting priority)
			
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
	
	highest_rel = 0
	# find which target has highest relevance
	for id in list:
		if list[id].relevance > 0.0:
			if highest_rel != 0:
				if list[id].relevance > list[highest_rel].relevance:
					highest_rel = id
			else:
				highest_rel = id

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

func is_target_on_camera(target:Dictionary) -> bool:
	# Rule out the stuff behind the camera.
	if Game.cam.is_position_behind(target.pos): return false
	
	# Check if within screen bounds
	var window_size := Rect2(Vector2.ZERO, OS.window_size).grow(half_corner_size) # always draw the partial graphic @ screen edge
	if   window_size.has_point(Vector2(target.aabb2d.position.x, target.aabb2d.position.y)): return true
	elif window_size.has_point(Vector2(target.aabb2d.end.x,      target.aabb2d.position.y)): return true
	elif window_size.has_point(Vector2(target.aabb2d.position.x, target.aabb2d.end.y)):      return true
	elif window_size.has_point(Vector2(target.aabb2d.end.x,      target.aabb2d.end.y)):      return true
	
	return false

func _draw(): # update called in player
	for id in list:
		var target = list[id]
		
		if not target.on_cam or target.relevance <= 0.0:
			continue # do not draw irrelevant targets
			
		var distance:float = (Game.cam.global_transform.origin - target.pos).length()
		var opacity:float = 1.0
		opacity = clamp(distance - 1.5, 0.0, 1.0)
#		opacity = 1.0 - clamp((distance - 15.0) / 5.0, 0.0, 1.0)
		
		var color = Color(0.4, 0.4, 0.4, opacity * 0.5) # grey
		if highest_rel == id:
			color = Color(0.45, 0.45, 0.75, opacity * 0.75) # dull blue
		if id == Game.player.zl_target:
			color = Color(0.5, 0.5, 1.0, opacity) # bright blue
		
		# where to draw the cursor corners:
		var upper_left_pos   = Rect2(Vector2(target.aabb2d.position.x - half_corner_size, target.aabb2d.position.y - half_corner_size), size)
		var upper_right_pos  = Rect2(Vector2(target.aabb2d.end.x - half_corner_size, target.aabb2d.position.y - half_corner_size), size)
		var bottom_left_pos  = Rect2(Vector2(target.aabb2d.position.x - half_corner_size, target.aabb2d.end.y - half_corner_size), size)
		var bottom_right_pos = Rect2(Vector2(target.aabb2d.end.x - half_corner_size, target.aabb2d.end.y - half_corner_size), size)
		
		# draw
		draw_texture_rect_region(cursor_tex, upper_left_pos,   upper_left_slice,   color)
		draw_texture_rect_region(cursor_tex, upper_right_pos,  upper_right_slice,  color)
		draw_texture_rect_region(cursor_tex, bottom_left_pos,  bottom_left_slice,  color)
		draw_texture_rect_region(cursor_tex, bottom_right_pos, bottom_right_slice, color)

# Called from Area node in player scene
func target_acquired(area: Area) -> void:
	# More properties assigned and updated when managing the target list in _physics_process
	# These ones are static so I can assign them here and never again.
	var id = area.get_instance_id()
	var parent = area.get_parent()
	list[id] = {
		"area": area,
		"parent": parent,
		"name": parent.name,
		"aabb": parent.get_aabb()
	}
func target_lost(area: Area) -> void:
	var id = area.get_instance_id()
# warning-ignore:return_value_discarded
	list.erase(id)
	
func debug() -> void:
	Debug.text.write('Target list:')
	for id in list:
		var target = list[id]
		Debug.text.write('[id:' + str(id) + '] ' + target.name + ' | Rel: ' + str(target.relevance), 'red' if target.relevance <= 0 else 'blue')
	Debug.text.newline()
