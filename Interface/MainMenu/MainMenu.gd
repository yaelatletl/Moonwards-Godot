extends CanvasLayer
"""
	MainMenu Singleton Scene Script
"""

onready var tabs: TabContainer = $"H/T"


func show() -> void:
	for i in get_children():
		if i is Control:
			i.visible = true
	
	PauseMenu.set_openable(false)


func hide() -> void:
	for i in get_children():
		if i is Control:
			i.visible = false
	
	PauseMenu.set_openable(true)


func _on_bJoinServer_pressed() -> void:
	pass
	# TODO: Reimplement calls to join server
#	UIManager.ui_event(UIManager.UI_EVENTS.JOIN_SERVER)
# FROM UIMANAGER.gd
#func join_server(scene: String) -> void:
#	if scene == null or scene == "":
#		scene = Options.scenes.default_multiplayer_join_server
#
#	var player_data = {
#		username = Options.username
#	}
#
#	GameState.player_register(player_data, true, "avatar") #local player
#	GameState.load_level(scene)
#	GameState.client_server_connect(Options.join_server_host)

func _on_bLocalGame_pressed() -> void:
	tabs.current_tab = 3


func _on_bOptions_pressed() -> void:
	tabs.current_tab = 1


func _on_bAbout_pressed() -> void:
	tabs.current_tab = 2


func _on_bQuit_pressed() -> void:
	Options.save_user_settings()
	get_tree().quit()
