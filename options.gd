extends Node
var id = "options.gd"
var debug = true

signal user_settings_changed

enum slots{
	pants,
	shirt,
	skin,
	hair
}

enum genders{
	female,
	male
}

var username
var gender
var pants_color
var shirt_color
var skin_color 
var hair_color
var savefile_json

var OptionsFile = "user://gameoptions.save"
var User_file = "user://settings.save"

func printd(s):
	logg.print_fd(id, s)

var scenes = {
	loaded = null,
	default = "WorldTest",
#	default_run_scene = "WorldTest2",
# 	default_run_scene = "WorldTest",
	default_run_scene = "WorldV2",
	default_singleplayer_scene = "WorldV2",
	default_multiplayer_scene = "WorldTest",
	default_multiplayer_headless_scene = "WorldTest",
	default_multiplayer_join_server = "WorldV2",
#	default_multiplayer_join_server = "WorldTest",
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
	LoadUserSettings()

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

func LoadUserSettings():
	var savefile = File.new()
	if not savefile.file_exists(User_file):
		SaveUserSettings()
	
	savefile.open(User_file, File.READ)
	print(savefile.get_as_text())
	savefile_json = parse_json(savefile.get_as_text())
	savefile.close()
	gender = SafeGetSetting("gender", genders.female)
	username = SafeGetSetting("username", "Player Name")
	
	pants_color = SafeGetColor("pants", Color8(49,4,5,255))
	shirt_color = SafeGetColor("shirt", Color8(87,235,192,255))
	skin_color = SafeGetColor("skin", Color8(150,112,86,255))
	hair_color = SafeGetColor("hair", Color8(0,0,0,255))

func SafeGetColor(var color_name, var default_color):
	if not savefile_json.has(color_name + "R") or not savefile_json.has(color_name + "G") or not savefile_json.has(color_name + "B"):
		return default_color
	else:
		return Color8(savefile_json[color_name + "R"],savefile_json[color_name + "G"],savefile_json[color_name + "B"],255)

func SafeGetSetting(var setting_name, var default_value):
	
	if not savefile_json.has(setting_name):
		return default_value
	else:
		return savefile_json[setting_name]

func SaveUserSettings():
	var savefile = File.new()
	savefile.open(User_file, File.WRITE)
	var save_dict = {
		
		"username" : username,
		"gender" : gender,
		
		"pantsR" : pants_color.r*255, # Vector3 is not supported by JSON
		"pantsG" : pants_color.g*255,
		"pantsB" : pants_color.b*255,
		
		"shirtR" : shirt_color.r*255,
		"shirtG" : shirt_color.g*255,
		"shirtB" : shirt_color.b*255,
		
		"skinR" : skin_color.r*255,
		"skinG" : skin_color.g*255,
		"skinB" : skin_color.b*255,
		
		"hairR" : hair_color.r*255,
		"hairG" : hair_color.g*255,
		"hairB" : hair_color.b*255,
		
		}
	savefile.store_line(to_json(save_dict))
	savefile.close()
	emit_signal("user_settings_changed")