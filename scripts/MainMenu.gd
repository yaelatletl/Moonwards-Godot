extends Control

func _ready_headless():
	print("Setup headless mode")
	var player_data = options.player_opt("server_bot")
	gamestate.player_register(player_data, true) #local player
	gamestate.server_set_mode()
	var worldscene = options.scenes.default_multiplayer_headless_scene
	gamestate.change_scene(worldscene)

func _ready():
	if utils.feature_check_server():
		_ready_headless()
	else:
		UIManager.RegisterBaseUI(self)
		UIManager.SetCurrentUI($VBoxContainer)
