extends "res://ui/MenuClass.gd"

enum { INVERT_X, INVERT_Y, DISTANCE, RESET_TO_DEFAULT }
onready var invert_x_value = $menu_items/InvertXAxis/Value 
onready var invert_y_value = $menu_items/InvertYAxis/Value

" Camera.custom_distance is the actual value "
const dist_default:float = 3.2
const dist_max:float = 5.0
const dist_min:float = 2.0
var dist_prior_value:float = 3.2
onready var custom_distance_color_rect_bg = $menu_items/CameraDistance/BG
onready var custom_distance_color_rect = $menu_items/CameraDistance/Visual
onready var custom_distance_value_label = $menu_items/CameraDistance/Numerical

var greyed_out:String = "505050"

var slider_controls_enabled:bool = false
const slider_width:float = 200.0 # pixels.

func _init():
	menu_items = ["Invert X Axis", "Invert Y Axis", "Camera Distance", "Reset to Default"]

func _ready() -> void:
	set_camera_distance(MainCam.custom_distance)

func set_camera_distance(value:float) -> void:
	MainCam.custom_distance = value
	custom_distance_value_label.text = str(value).pad_decimals(3)
	custom_distance_color_rect.rect_size.x = inverse_lerp(dist_min, dist_max, value) * slider_width

# Only update the menu when appropriate
func _up_pressed() -> void:
	if not slider_controls_enabled:
		._up_pressed() # call MenuClass function to update the index
func _down_pressed() -> void:
	if not slider_controls_enabled:
		._down_pressed()

func _return_pressed() -> void:
	if slider_controls_enabled:
		change_slider_state(DISTANCE, false)
		set_camera_distance(dist_prior_value)
	else:
		current_menu_index = 0
		UI.paused.change_state("customize_menu")
		stop()
	
func _menu_item_selected(index):
	match index:
		INVERT_X:
			MainCam.invert_x = not MainCam.invert_x
			invert_x_value.text = str(MainCam.invert_x).capitalize()
		INVERT_Y:
			MainCam.invert_y = not MainCam.invert_y
			invert_y_value.text = str(MainCam.invert_y).capitalize()
		DISTANCE:
			if slider_controls_enabled:
				change_slider_state(DISTANCE, false) # disable
			else:
				dist_prior_value = MainCam.custom_distance
				change_slider_state(DISTANCE, true) # enable
		RESET_TO_DEFAULT:
			MainCam.invert_x = false
			invert_x_value.text = "False"
			MainCam.invert_y = false
			invert_y_value.text = "False"
			set_camera_distance(dist_default)

func change_slider_state(index:int, state:bool) -> void:
	slider_controls_enabled = state
	match index:
		DISTANCE:
			if state == true:
				custom_distance_color_rect_bg.color = Color("808040")
				custom_distance_color_rect.color = Color("ffff80")
				custom_distance_value_label.self_modulate = Color("ffff80");
			else:
				custom_distance_color_rect_bg.color = greyed_out
				custom_distance_color_rect.color = Color("808080")
				custom_distance_value_label.self_modulate = unselected;

func _process(_t:float) -> void:
	if slider_controls_enabled:
		var slide_amount:float = 0.0
		
		if Input.is_action_pressed("d-left"):
			slide_amount -= 0.001
		elif Input.is_action_pressed("ui_left"):
			slide_amount -= 0.01
		
		if Input.is_action_pressed("d-right"):
			slide_amount += 0.001
		elif Input.is_action_pressed("ui_right"):
			slide_amount += 0.01
		
		if slide_amount != 0.0:
			match current_menu_index:
				DISTANCE:
					slide_amount *= 2.0
					set_camera_distance(clamp(MainCam.custom_distance + slide_amount, dist_min, dist_max))

