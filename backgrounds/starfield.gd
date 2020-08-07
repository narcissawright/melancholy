extends Control

"""
Would like to move the actual star texture drawing to a shader for GPU.
"""

var textures = []
const STARTOTAL = 2000
const SIZE_INDEX = 0
const POSITION_INDEX = 1
const COLOR_INDEX = 2
var sun_vec = Vector3(-0.446634, 0.893269, 0.050884).normalized()
onready var sunlight = $'SunLight'
var axis_of_rotation = Vector3(1, 0.5 ,0).normalized()
#onready var sun_tex = load("res://img/sun.png")
onready var blackbody_radiation = load('res://backgrounds/blackbody_radiation.tres')
#var we = null # worldenvironment child node for setting ambient light based on time of day

var star_field = null

func _ready():
	$WorldEnvironment.environment.background_mode = Environment.BG_CANVAS
	# Changing this to canvas only at runtime helps the editor not look awful.
	
	#if self.has_node('WorldEnvironment'):
	#	we = $'WorldEnvironment'
	textures.push_back(load("res://img/star_0_hd.png"))
	textures.push_back(load("res://img/star_1_hd.png"))
	textures.push_back(load("res://img/star_2_hd.png"))
	if star_field == null:
		create_star_field()

func _process(_delta):
	
	update() #calls _draw()

func fix_saturation(brightness):
	if brightness < 0.15:
		return 0.15
	elif brightness > 0.85:
		return 0.85
	return brightness

func create_star_field():
	var field = []
	var r
	var g
	var b
	var size
	randomize()
	for i in range (1,STARTOTAL):
		size = 0
		if i % 5 == 0:
			size += 1
		if i % 50 == 0:
			size += 1
		
		if size == 0:
			r = randf() / 3
			g = randf() / 5
			b = randf()
			
		if size == 1:
			r = randf() / 2
			g = randf() / 3
			b = randf() * 1.5
			if b > 1:
				b = 1
		
		if size == 2:
			r = fix_saturation(randf())
			g = fix_saturation(randf())
			b = fix_saturation(randf())
		
		var radiation = blackbody_radiation.gradient.interpolate(randf())
		var color = radiation.linear_interpolate(Color(r,g,b), 0.5)
		color.a = (randf()/2) + 0.5
		var position = Vector3(gaussian(0,1), gaussian(0,1), gaussian(0,1)).normalized()
		field.push_back([size, position, color])
	
	star_field = field

func gaussian(mean, deviation):
	var x1 = null
	var x2 = null
	var w = null
	while true:
		x1 = rand_range(0, 2) - 1
		x2 = rand_range(0, 2) - 1
		w = x1*x1 + x2*x2
		if 0 < w && w < 1:
			break
	w = sqrt(-2 * log(w)/w)
	return (mean + deviation * x1 * w)

func _draw():
	var rot_amount = (Game.time_of_day / 1440.0) * 360
	var cam_pos = Game.cam.global_transform.origin
	var bounds = Rect2(-64, -64, 1920 + 128, 1080 + 128)
	
	#var c = Color('050510')
	var c = Color('181822')
		
	draw_rect(bounds, c, true)
		
	for star in star_field:
		var world_point = cam_pos + star[POSITION_INDEX].rotated(axis_of_rotation, deg2rad(rot_amount) )
		if Game.cam.is_position_behind(world_point):
			var pos = Game.cam.unproject_position(world_point)
			pos.x = round(pos.x)
			pos.y = round(pos.y)
			if bounds.has_point(pos):
				var star_c = star[COLOR_INDEX]
				#var color_sum = (star_c.r + star_c.g + star_c.b + star_c.a) / 4.0
				#var star_opacity
				draw_texture (textures[star[SIZE_INDEX]], pos, star_c)
	
	var sun_rot = sun_vec.rotated(axis_of_rotation, deg2rad(rot_amount) )
	
	Debug.draw.begin(Mesh.PRIMITIVE_LINES)
	Debug.draw.set_color(Color(1,1,0))
	Debug.draw.add_vertex(Vector3(0, 2.5, 0))
	Debug.draw.set_color(Color(0.3,0.3,1))
	Debug.draw.add_vertex(Vector3(0, 2.5, 0) + sun_rot)
	Debug.draw.end()
	
	sunlight.look_at(sun_rot, Vector3.UP)
	sunlight.light_energy = ((-sun_rot.y + 1.0) / 2.0)
