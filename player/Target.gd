extends Node2D

var cursor_tex = load("res://img/target.png")
var target_list:Array = []  # assigned in player

const size := Vector2(15, 15) # cursor corner size, in pixels 
const half_size:int = 7 # rounded down
const upper_left_slice   := Rect2(Vector2(0, 0),      size) # how to slice up orb_crosshair.png
const upper_right_slice  := Rect2(Vector2(size.x, 0), size)
const bottom_left_slice  := Rect2(Vector2(0, size.y), size)
const bottom_right_slice := Rect2(size,               size)

func _draw(): # update called in player
	for i in range (target_list.size()):
		if target_list[i].blocked:
			continue # if no direct line of sight to the target, do not draw crosshair
			
		var t_pos:Vector3 = target_list[i].target_pos # target position in 3d space
		if Game.cam.is_position_behind(t_pos):
			continue # if target is behind the camera, do not draw crosshair
		
		var pos_2d:Vector2 = Game.cam.unproject_position(t_pos) # find 2d position of target in viewport
		var aabb_pos:Vector3 = target_list[i].aabb.position # bounding box starting corner (x, y, z)
		var aabb_size:Vector3 = target_list[i].aabb.size # bounding box size (x, y, z)
		
		# a list of the 8 vertices that make up the axis aligned bounding box assigned to this target
		var points := [
			t_pos + aabb_pos,
			t_pos + aabb_pos + Vector3(aabb_size.x, 0, 0),
			t_pos + aabb_pos + Vector3(0, aabb_size.y, 0),
			t_pos + aabb_pos + Vector3(0, 0, aabb_size.z),
			t_pos + aabb_pos + Vector3(aabb_size.x, aabb_size.y, aabb_size.z),
			t_pos + aabb_pos + Vector3(0, aabb_size.y, aabb_size.z),
			t_pos + aabb_pos + Vector3(aabb_size.x, 0, aabb_size.z),
			t_pos + aabb_pos + Vector3(aabb_size.x, aabb_size.y, 0)
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
		
		var distance:float = (Game.cam.global_transform.origin - t_pos).length()
		var opacity:float = 1.0
		opacity = clamp(distance - 1.5, 0.0, 1.0)
#		opacity = 1.0 - clamp((distance - 15.0) / 5.0, 0.0, 1.0)
		
		var color = Color(0.66, 0.75, 0, opacity) # yellow, not seeking this target
		if target_list[i].seeking:
			color = Color(1, 0.2, 0.15, opacity) # red
		
		# where to draw the cursor corners:
		var upper_left_pos   = Rect2(Vector2(x_min - half_size, y_min - half_size), size)
		var upper_right_pos  = Rect2(Vector2(x_max - half_size, y_min - half_size), size)
		var bottom_left_pos  = Rect2(Vector2(x_min - half_size, y_max - half_size), size)
		var bottom_right_pos = Rect2(Vector2(x_max - half_size, y_max - half_size), size)
		
		# draw
		draw_texture_rect_region(cursor_tex, upper_left_pos,   upper_left_slice,   color)
		draw_texture_rect_region(cursor_tex, upper_right_pos,  upper_right_slice,  color)
		draw_texture_rect_region(cursor_tex, bottom_left_pos,  bottom_left_slice,  color)
		draw_texture_rect_region(cursor_tex, bottom_right_pos, bottom_right_slice, color)
