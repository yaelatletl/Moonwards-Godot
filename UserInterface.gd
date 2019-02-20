extends Node

var SceneOptions = "res://assets/UI/Menu/Options.tscn"
var Options = null


func _input(event):
	if event.is_action_pressed("ui_menu_options"):
		OptionsPanel()

func OptionsPanel():
		if Options:
			options.set("_state_", Options.get_tab_index(), "menu_options_tab")
			Options.queue_free()
			Options = null
		else:
			Options = ResourceLoader.load(SceneOptions).instance()
			Options.signal_close = true
			Options.connect("close", self, "OptionsPanel")
			Options.set_tab_index(options.get("_state_", "menu_options_tab", 1))
			get_tree().get_root().add_child(Options)
			
