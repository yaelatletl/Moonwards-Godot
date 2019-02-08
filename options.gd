extends Node

var OptionsFile = "user://gameoptions.save"
var debug = true

var scenes = {
	loaded = null,
	default = "WorldTest",
	World = {
		path = "res://World.tscn"
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
	print("debug set FPS to 3")
	Engine.target_fps = 3
	print("load options and settings")
	self.load()

func load():
	var savefile = File.new()
	if not savefile.file_exists(OptionsFile):
		print("Nothing was saved before")
	else:
		savefile.open(OptionsFile, File.READ)
		var content = parse_json(savefile.get_as_text())
		savefile.close()

func save():
	var savefile = File.new()	
	savefile.open(OptionsFile, File.WRITE)
	savefile.store_line(to_json(options))
	savefile.close()

func get(category, prop = null):
	var res
	if options.has(category):
		if prop and options[category].has(prop):
			res = options[category][prop]
		else:
			res = options[category]
	return res
	
func set(category, value, prop = null):
	if category and prop:
		options[category][prop] = value
	elif category:
		options[category] = value
	else:
		print("error setting option (%s, %s, %s)" % [category, value, prop])
