extends Node


onready var tabs: TabContainer = $"H/T"


func _on_bJoinServer_pressed() -> void:
	# TODO: Replace UIManager
	UIManager.ui_event(UIManager.UI_EVENTS.JOIN_SERVER)


func _on_bLocalGame_pressed() -> void:
	tabs.current_tab = 3


func _on_bOptions_pressed() -> void:
	tabs.current_tab = 1


func _on_bAbout_pressed() -> void:
	tabs.current_tab = 2


func _on_bQuit_pressed() -> void:
	Options.save_user_settings()
	get_tree().quit()
