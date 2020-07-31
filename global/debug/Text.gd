extends RichTextLabel

var color_list:Dictionary = {
	'green': '#10ee10',
	'red': '#ff3030',
	'blue': '#8080ff'
}

func _ready() -> void:
	process_priority = -50
	
func _physics_process(_t:float) -> void:
	bbcode_text = ''

func write(string:String, color:String = "white"):
	if color_list.has(color):
		color = color_list[color]
	bbcode_text += '[color=' + color + ']' + string + '[/color]' + '\n'

func newline():
	bbcode_text += '\n'
