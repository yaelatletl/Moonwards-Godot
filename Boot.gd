extends Node
"""
	Boot Scene Script
	Initializes headless server if required
"""

func _ready() -> void:
	if OS.has_feature("Server"):
		_ready_headless()
	else:
		MainMenu.show()
	# originally registered ui in uimanager


func _ready_headless() -> void:
	Log.hint(self, "_ready_headless", "Initializing Headless Server")
	
	var player_data : Dictionary = {
		name = "Server Bot",
		options = Options.player_opt("server_bot")
	}
	Lobby.player_register(player_data, true) #local player
	Lobby.server_set_mode()
	var worldscene : String = Options.scenes.default_multiplayer_join_server
	Lobby.change_scene(worldscene)
