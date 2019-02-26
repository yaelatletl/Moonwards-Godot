extends Control
export(String) var SceneToLoad = "res://World.tscn"
export(String) var SceneOptions = "res://assets/UI/Menu/Options.tscn"
const MultiplayerToLoad = "res://lobby.tscn"
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	_on_size_changed()
	get_viewport().connect("size_changed",self,"_on_size_changed")


func _on_size_changed():
	var Newsize = get_viewport().get_visible_rect().size
	rect_scale = Vector2(1,1)*(Newsize.y/rect_size.y)

func _on_Run_pressed():
	$ui/main.hide()
	$ui/loading.show()
	$load_timer.start()

func _on_Timer_timeout():
	get_tree().change_scene(SceneToLoad)


func _on_Help_pressed():
	if $ui/main/pHelp.visible :
		$ui/main/pHelp.hide()
	else:
		$ui/main/pHelp.show()


func _on_RunNet_pressed():
	$ui/main.hide()
	$ui/loading.show()
	$PlayerSettings.hide()
	var  mScene = ResourceLoader.load(MultiplayerToLoad)
	var loads = mScene.instance()
	loads.name = "lobby"
	get_tree().get_root().add_child(loads)


func _on_Options_pressed():
	if get_tree().get_root().has_node("Options"):
		get_tree().get_root().get_node("Options").show()
	else:
		var Options = ResourceLoader.load(SceneOptions)
		Options = Options.instance()
		Options.name = "Options"
		get_tree().get_root().add_child(Options)
