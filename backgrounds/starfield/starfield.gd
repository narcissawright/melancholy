extends Control

"""
Would like to move the actual star texture drawing to a shader for GPU.
"""

enum { SIZE_INDEX, POSITION_INDEX, COLOR_INDEX }

const textures := [
	preload("res://backgrounds/starfield/star_0_hd.png"),
	preload("res://backgrounds/starfield/star_1_hd.png"),
	preload("res://backgrounds/starfield/star_2_hd.png")
]
const STARTOTAL:int = 2000
var sun_vec := Vector3(-0.446634, 0.893269, 0.050884).normalized()
onready var sunlight:DirectionalLight = $'SunLight'
var axis_of_rotation := Vector3(1, 0.5 ,0).normalized()
#onready var sun_tex = load("res://img/sun.png")
const blackbody_radiation:GradientTexture = preload('res://backgrounds/starfield/blackbody_radiation.tres')

var star_field:Array = []

func _ready():
	$WorldEnvironment.environment.background_mode = Environment.BG_CANVAS
	# Changing this to canvas only at runtime helps the editor not look awful.

	if star_field.empty():
		create_star_field()

func _process(_delta):
	update() #calls _draw()


func create_star_field():
	randomize()
	for i in range (1,STARTOTAL):
		var r:float
		var g:float
		var b:float
		var size:int = 0
		if i % 5 == 0:
			size += 1
		if i % 50 == 0:
			size += 1
		
		if size == 0:
			r = randf() / 3.0
			g = randf() / 5.0
			b = randf()
			
		if size == 1:
			r = randf() / 2.0
			g = randf() / 3.0
			b = max(randf() * 1.5, 1.0)
		
		if size == 2:
			r = clamp(randf(), 0.15, 0.85)
			g = clamp(randf(), 0.15, 0.85)
			b = clamp(randf(), 0.15, 0.85)
		
		var radiation = blackbody_radiation.gradient.interpolate(randf())
		var color = radiation.linear_interpolate(Color(r,g,b), 0.5)
		color.a = (randf()/2.0) + 0.5
		var position = Vector3(gaussian(0,1), gaussian(0,1), gaussian(0,1)).normalized()
		star_field.push_back([size, position, color])

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
	var rot_amount = (Timekeeper.time_of_day / 1440.0) * TAU
	var bounds = Rect2(-64, -64, 1920 + 128, 1080 + 128)
	draw_rect(bounds, Color('181822'), true)
	
	for star in star_field:
		var world_point = MainCam.global_transform.origin + star[POSITION_INDEX].rotated(axis_of_rotation, deg2rad(rot_amount) )
		if MainCam.is_position_behind(world_point):
			var pos = MainCam.unproject_position(world_point)
			pos.x = round(pos.x)
			pos.y = round(pos.y)
			if bounds.has_point(pos):
				var star_c = star[COLOR_INDEX]
				draw_texture(textures[star[SIZE_INDEX]], pos, star_c)
	
	var sun_rot = sun_vec.rotated(axis_of_rotation, rot_amount)
	sunlight.look_at(sun_rot, Vector3.UP)
	sunlight.light_energy = ((-sun_rot.y + 1.0) / 2.0)
	
#	Debug.draw.begin(Mesh.PRIMITIVE_LINES)
#	Debug.draw.set_color(Color(1,1,0))
#	Debug.draw.add_vertex(Vector3(0, 2.5, 0))
#	Debug.draw.set_color(Color(0.3,0.3,1))
#	Debug.draw.add_vertex(Vector3(0, 2.5, 0) + sun_rot)
#	Debug.draw.end()
