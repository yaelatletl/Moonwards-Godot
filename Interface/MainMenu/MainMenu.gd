extends Node


onready var tabs: TabContainer = $"Menu/H/T"


func _on_bJoinServer_pressed() -> void:
	pass # Replace with function body.


func _on_bLocalGame_pressed() -> void:
	pass # Replace with function body.


func _on_bOptions_pressed() -> void:
	pass # Replace with function body.


func _on_bAbout_pressed() -> void:
	pass # Replace with function body.


func _on_bQuit_pressed() -> void:
	Options.save_user_settings()
	get_tree().quit()
