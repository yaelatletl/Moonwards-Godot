extends Node

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

func _ready():
	pass
