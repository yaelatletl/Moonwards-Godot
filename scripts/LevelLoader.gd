extends Node

var path = ""
var error = OK
var loader = null
var thread : Thread = Thread.new()
var new_scene = null
var progress : float = 0.0
var loading_screen_resource :PackedScene= preload("res://assets/UI/Menu/Resources/LoadingScreen.tscn")
var loading_screen = null

func reset():
	var path = ""
	error = OK
	loader = null
	new_scene = null
	progress = 0.0

func start_loading(var path):
	reset()
	#Switch to the LoadingScreen before starting the Thread that loads the new level.
	loading_screen = loading_screen_resource.instance()
	gamestate.get_tree().get_root().add_child(loading_screen)
	gamestate.get_tree().current_scene.queue_free()
	gamestate.get_tree().current_scene = loading_screen
	
	self.path = path
	var already = thread.is_active()
	thread.start(self, "threat_start_loading", path)

func threat_start_loading(var path):
	if path is PackedScene:
		loader = ResourceLoader.load_interactive(path.get_path())
	else:
		loader = ResourceLoader.load_interactive(path)
	if loader == null:
		call_deferred('background_loading_done')
		return ERR_CANT_ACQUIRE_RESOURCE
	return thread_loading()
	
func thread_loading():
	while true:
		if check_loading():
			call_deferred('background_loading_done')
			return error

func background_loading_done():
	var result = thread.wait_to_finish()
	loading_screen.queue_free()
	gamestate.loading_done(result)

func check_loading():
	error = loader.poll()
	if error == ERR_FILE_EOF or error == OK:
		progress = loader.get_stage() / max(1.0, (loader.get_stage_count() - 1)) * 100.0
		gamestate.emit_signal("loading_progress", progress)
		if error == ERR_FILE_EOF:
			new_scene = loader.get_resource()
			return true
	else:
		return true
	return false