extends Node

var OptionsFile = "user://gameoptions.save"

var debug = true
var debug_id = "Options:: "
var debug_list = [
	{ enable = false, key = "options set TreeManagerCache" },
	{ enable = false, key = "get: TreeManagerCache" },
#	{ enable = true, key = "" }
]
func printd(s):
	if debug:
		if debug_list.size() > 0:
			var found = false
			for dl in debug_list:
				if s.begins_with(dl.key):
					if dl.enable:
						print(debug_id, s)
					found = true
					break
			if not found:
				print(debug_id, s)
		else:
			print(debug_id, s)

var scenes = {
	loaded = null,
	default = "WorldTest",
#	default_run_scene = "WorldV2Player",
#	default_run_scene = "WorldTest2",
# 	default_run_scene = "WorldTest",
	default_run_scene = "WorldV2PlayerV2",
	default_singleplayer_scene = "WorldV2",
	default_multiplayer_scene = "WorldTest",
	default_multiplayer_headless_scene = "WorldTest",
	default_multiplayer_join_server = "WorldV2",
#	default_multiplayer_join_server = "WorldTest",
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
	},
	WorldV2PlayerV2 = {
		path = "res://WorldV2PlayerV2.tscn"
	}
}

var player_opt = {
	player_group = "player",
	opt_allow_unknown = true,
	PlayerGroup = "PlayerGroup", #local player group
	opt_filter = {
		debug = true,
		nocamera = true,
		username = true,
		is_female = true
	},
	avatar = {
		debug = debug,
		nocamera = false,
		input_processing = true,
		network = true,
		puppet = false,
		physics_scale = 0.1,
		IN_AIR_DELTA = 0.4
	},
	avatar_local = {
		debug = debug,
		nocamera = false,
		input_processing = true,
		network = false,
		puppet = false,
		physics_scale = 0.1,
	},
	puppet = {
		debug = debug,
		nocamera = true,
		input_processing = false,
		network = true,
		puppet = true
	},
	server_bot = {
		debug = debug,
		nocamera = true,
		network = true,
		puppet = false,
		username = "Server Bot"
	}
}

func set_defaults():
	# set some default values, probably improve that
	get("dev", "enable_areas_lod", true)
	get("dev", "enable_collision_shapes", true)
	get("dev", "3FPSlimit", true)
	get("dev", "3FPSlimit_value", 30)
	get("dev", "hide_meshes_random", false)
	get("dev", "decimate_percent", 90)
	get("dev", "TreeManager", true)
	get("LOD", "lod_aspect_ratio", 150)
	# get("dev", "lod_manager_path", "res://scripts/TreeManager.tscn")

func player_opt(type, opt = null):
	var res = {}
	var filter = player_opt.opt_filter
	var filter_id = "opt_filter_%s" % type
	if player_opt.has(filter_id):
		filter = player_opt[filter_id]

	var allow_unknown = player_opt.opt_allow_unknown
	if opt != null:
		for k in opt:
			if filter.has(k) and filter[k] or allow_unknown:
				res[k] = opt[k]
				if not k in filter:
					printd("player_filter_opt, default allow unknown option %s %s" % [k, opt[k]])

	if not player_opt.has(type):
		printd("player_filter_opt, unknown player opt type %s" % type)
	else:
		var def_opt = player_opt[type]
		for k in def_opt:
			res[k] = def_opt[k]
	return res

#scene for players, node name wich serves an indicator
var scene_id = "scene_id_30160"

#scene we instance for each player
var player_scene = preload("res://assets/Player/avatar_v2/player.tscn")

#Join server host
#var join_server_host = "127.0.0.1"
#var join_server_host = "moonwards.hopto.org"
var join_server_host = "mainhabs.moonwards.com"

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
	printd("load options and settings")
	self.load()
	set_defaults()
	
	#apply generic options
	set_3fps(get("dev", "3FPSlimit"))

func load():
	var savefile = File.new()
	if not savefile.file_exists(OptionsFile):
		printd("Nothing was saved before")
	else:
		savefile.open(OptionsFile, File.READ)
		var content = str2var(savefile.get_as_text())
		savefile.close()
		if content:
			if content.has("_state_"):
				content.erase("_state_")
			options = content
		printd("options loaded from %s" % OptionsFile)

func save():
	var savefile = File.new()	
	savefile.open(OptionsFile, File.WRITE)
	set("_state_", gamestate.local_id, "game_state_id")
	savefile.store_line(var2str(options))
	savefile.close()
	printd("options saved to %s" % OptionsFile)

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
	printd("get: %s::%s==%s" % [category, prop, res])
	return res
	
func set(category, value, prop = null):
	printd("options set %s::%s %s" % [category, prop, value])
	if prop == null:
		options[category] = value
	else:
		if not options.has(category):
			options[category] = {}
		options[category][prop] = value

func del_state(prop):
	printd("options del_stat ::%s" % prop)
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
	#get options under Node-Options
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
		printd("debug set FPS to 3")
		Engine.target_fps = 3
	else:
		printd("debug set FPS to 0")
		Engine.target_fps = 0
