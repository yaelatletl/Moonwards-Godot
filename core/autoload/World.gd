extends Node

signal scene_change(name)

var level_loader : Object = preload("res://scripts/LevelLoader.gd").new()
var world : Node = null

func change_scene(scene : String) -> void:
	var error
	if not scene in Options.scenes:
		Log.hint(self, "change_scene", "No such scene registered in options, attempting to load : %s" % scene)
		error = get_tree().change_scene(scene)
		if error == OK:
			emit_signal("scene_change", scene)
			return
		else:
			Log.error(self, "change_scene", "error changing scene, provided string is not a resource nor a scene")
			return
	else:
		Log.hint(self, "change_scene", "change_scene to %s" % scene)
		error = get_tree().change_scene(Options.scenes[scene].path)
		if error == 0 :
			Log.hint(self, "change_scene", "changing scene okay(%s)" % Log.error_to_string(error))
			Options.scenes.loaded = scene
			emit_signal("scene_change", scene)
			return
	Log.hint(self, "change_scene", "error changing scene %s" % Log.error_to_string(error))


"""
This is legacy code that needs checking

func loading_done(var error : int) -> void:
	if error == OK or error == ERR_FILE_EOF:
		Log.hint(self, "loading_done", "changing scene okay(%s)" % level_loader.error)
		emit_signal("loading_done")
	else:
		Log.hint(self, "loading_done", "error changing scene %s" % level_loader.error)
		Log.hint(self, "loading_done", "Error! " + Log.error_to_string(error))

func load_level(var resource) -> void: #Resource is variant
	# Check if the resource is valid before switching to loading screen.
	if resource is String:
		if Options.scenes.has(resource):
			resource = Options.scenes[resource].path
		if not ResourceLoader.exists(resource):
			emit_signal("loading_error", "File does not exist: " + resource)
			return
	elif resource is PackedScene:
		if not resource.can_instance():
			emit_signal("loading_error", "Can not instance resource.")
			return

	level_loader.start_loading(resource)
	yield(self, "loading_done")

	world = level_loader.new_scene.instance()
	get_tree().get_root().add_child(world)
	get_tree().current_scene = world
	emit_signal("scene_change")
	
	"""
