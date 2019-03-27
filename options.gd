extends Node

var OptionsFile = "user://gameoptions.save"
var debug = true

var scenes = {
	loaded = null,
	default = "WorldTest",
	default_run_scene = "WorldV2Player",
#	default_run_scene = "WorldTest2",
#	default_run_scene = "WorldTest",
	default_singleplayer_scene = "WorldV2",
	default_mutiplayer_scene = "WorldTest",
	World = {
		path = "res://World.tscn"
	},
	WorldV2Player = {
		path = "res://WorldV2Player.tscn",
		hint = "World with player scene"
	},
	WorldAC = {
		path = "res://World.tscn",
		hint = "World with active camera"
	},
	WorldV2 = {
		path = "res://WorldV2.tscn"
	},
	WorldTest = {
		path = "res://_tests/scene_mp/multiplayer_test_scene.tscn"
	},
	WorldTest2 = {
		path = "res://_tests/scene_mp/multiplayer_test_scene2.tscn"
	}
}

#scene for players, node name wich serves an indicator
var scene_id = "scene_id_30160"

#scene we instance for each player
var player_scene = preload("res://assets/Player/player.tscn")

############################
############################
#Other options
var options = {
	player = {
		color = Color8(50, 100, 150,255),
		name = "PlayerDefaultName"
	}
}

func _ready():
# 	print("debug set FPS to 3")
# 	Engine.target_fps = 3
	print("load options and settings")
	self.load()
	
	#apply generic options
	set_3fps(get("dev", "3FPSlimit"))

func load():
	var savefile = File.new()
	if not savefile.file_exists(OptionsFile):
		print("Nothing was saved before")
	else:
		savefile.open(OptionsFile, File.READ)
		var content = str2var(savefile.get_as_text())
		savefile.close()
		if content:
			if content.has("_state_"):
				content.erase("_state_")
			options = content
		print("options loaded from %s" % OptionsFile)

func save():
	var savefile = File.new()	
	savefile.open(OptionsFile, File.WRITE)
	set("_state_", gamestate.local_id, "game_state_id")
	savefile.store_line(var2str(options))
	savefile.close()
	print("options saved to %s" % OptionsFile)

func get(category, prop = null, default=null):
	var res
	if options.has(category):
		if prop and options[category].has(prop):
			res = options[category][prop]
		elif prop:
			pass
		else:
			res = options[category]
	if res == null and default != null:
		if prop:
			if not options.has(category):
				options[category] = {}
			options[category][prop] = default
		else:
			options[category] = default
		res = default
	print("Options.get: %s::%s==%s" % [category, prop, res])
	return res
	
func set(category, value, prop = null):
	print("options set %s::%s %s" % [category, prop, value])
	if prop == null:
		options[category] = value
	elif not options.has(category):
		options[category] = {}
	options[category][prop] = value

func del_state(prop):
	print("options del_stat ::%s" % prop)
	if options.has("_state_"):
		if options["_state_"].has(prop):
			options["_state_"].erase(prop)

func has(category, prop = null):
	var exists = false
	if options.has(category):
		exists = true
	if exists and prop != null:
		exists = options[category].has(prop)
	return exists

func get_tree_options(tree):
	var arr = utils.get_nodes_type(tree, "Node")
	var Options
	for p in arr:
		var obj = tree.get_node(p)
		if obj.name == "Options":
			Options = obj
			break
	return Options

func get_tree_opt(opt):
	var res = false
	var root = get_tree().current_scene
	if root == null:
		return res
	#get options unde Node-Options
	#
	var Options = get_tree_options(root)
	if Options:
		var obj = Options.get_node(opt)
		if obj:
			res = true
	return res


################
func set_3fps(enable):
	if enable:
		print("debug set FPS to 3")
		Engine.target_fps = 3
	else:
		print("debug set FPS to 0")
		Engine.target_fps = 0
