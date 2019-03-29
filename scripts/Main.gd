extends Control
export(String) var SceneToLoad = "res://World.tscn"
export(String) var SceneOptions = "res://assets/UI/Menu/Options.tscn"
const MultiplayerToLoad = "res://lobby.tscn"
var current_ui = null

# Called when the node enters the scene tree for the first time.
func _ready():
	if utils.feature_check_server():
		_ready_headless()
		return
	_on_size_changed()
	get_viewport().connect("size_changed",self,"_on_size_changed")

func _ready_headless():
	print("Setup headless mode")
	var player_data = {
		name = "Server Bot",
		options = {
			debug = false,
			nocamera = true
		}
	}
	gamestate.player_register(player_data, true) #local player
	gamestate.server_set_mode()
	var worldscene = options.scenes.default_mutiplayer_headless_scene
	gamestate.change_scene(worldscene)

func _on_size_changed():
	var Newsize = get_viewport().get_visible_rect().size
	rect_scale = Vector2(1,1)*(Newsize.y/rect_size.y)

func _on_Run_pressed():
	$ui/MainUI.hide()
	$ui/ProgressBar.show()
	$load_timer.start()

func _on_Timer_timeout():
	var worldscene = options.scenes.default_run_scene
	gamestate.change_scene(worldscene)

func _on_Help_pressed():
	$ui/MainUI/InstructionsContainer.visible = !$ui/MainUI/InstructionsContainer.visible

func _on_RunNet_pressed():
	$ui/MainUI.hide()
	$ui/PlayerSettings.hide()
	var  mScene = ResourceLoader.load(MultiplayerToLoad)
	var loads = mScene.instance()
	loads.name = "lobby"
	$ui/Logo.hide()
	get_tree().get_root().add_child(loads)

func _on_Options_pressed():
	if get_tree().get_root().has_node("Options"):
		get_tree().get_root().get_node("Options").show()
	else:
		var Options = ResourceLoader.load(SceneOptions)
		Options = Options.instance()
		Options.name = "Options"
		get_tree().get_root().add_child(Options)

func OnUIEvent(var event):
	if event == "Back":
		current_ui.disconnect("ui_event", self, "OnUIEvent")
		$ui/MainUI.show()
		current_ui.hide()
		current_ui = null

func _on_CfgPlayer_pressed():
	SwitchUI($ui/PlayerSettings)

func SwitchUI(var new_ui):
	$ui/MainUI.hide()
	current_ui = new_ui
	current_ui.show()
	current_ui.connect("ui_event", self, "OnUIEvent")
