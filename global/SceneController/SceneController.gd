extends Node

var frame_time:float = 1.0 / 60.0

func _init() -> void:
	OS.window_size = Vector2(1280, 720)
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)

func _ready() -> void:
	pause_mode = Node.PAUSE_MODE_PROCESS # Run this script while paused
	Events.connect("unpause_game", self, "unpause_game")
	Events.connect("quit_game", self, "quit_game")

func _input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("fullscreen"):
		Input.action_release("fullscreen")
		OS.window_fullscreen = !OS.window_fullscreen
	if Input.is_action_just_pressed("pause"):
		Input.action_release("pause")
		toggle_pause()

func unpause_game() -> void:
	if get_tree().paused:
		get_tree().paused = false
		Events.emit_signal("pause", false)

func toggle_pause() -> void:
	get_tree().paused = not get_tree().paused
	Events.emit_signal("pause", get_tree().paused)

func quit_game() -> void:
	get_tree().quit()
