extends Node

var SceneOptions = "res://assets/UI/Options.tscn"
var Options = null


func _input(event):
	if event.is_action_pressed("ui_menu_options"):
		OptionsPanel()

func OptionsPanel():
		if Options:
			Options.queue_free()
			Options = null
		else:
			Options = ResourceLoader.load(SceneOptions).instance()
			Options.signal_close = true
			Options.connect("close", self, "OptionsPanel")
			get_tree().get_root().add_child(Options)
			
