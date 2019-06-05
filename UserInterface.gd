extends Control

var SceneOptions = "res://assets/UI/Menu/Options.tscn"
var SceneMenu = "res://assets/UI/Menu/In_game_menu.tscn"
var SceneDiagram = "res://assets/UI/Diagram.tscn"
var Options = null
var added_menu_ui = false
var diagram_visible = false

func _ready():
	UIManager.RegisterBaseUI(self)
	UIManager.NextUI(SceneDiagram)

func _input(event):
	if event.is_action_pressed("ui_menu_options"):
		if added_menu_ui:
			UIManager.ClearUI()
		elif UIManager.RequestFocus():
			UIManager.NextUI(SceneMenu)
		added_menu_ui = not added_menu_ui
	if event.is_action_pressed("show_diagram"):
		if diagram_visible:
			UIManager.ClearUI()
		elif UIManager.RequestFocus():
			UIManager.NextUI(SceneDiagram)
		diagram_visible = not diagram_visible

func OptionsPanel():
		if Options:
			options.set("_state_", Options.get_tab_index(), "menu_options_tab")
			Options.queue_free()
			Options = null
			options.save()
			Input.set_mouse_mode(options.get("_state_", "menu_options_mm", Input.MOUSE_MODE_VISIBLE))
		else:
			Options = ResourceLoader.load(SceneOptions).instance()
			Options.signal_close = true
			Options.connect("close", self, "OptionsPanel")
			Options.set_tab_index(options.get("_state_", "menu_options_tab", 1))
			get_tree().get_root().add_child(Options)
			options.set("_state_", Input.get_mouse_mode(), "menu_options_mm")
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
