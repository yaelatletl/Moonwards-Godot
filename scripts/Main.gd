extends Control
export(String) var SceneToLoad = "res://World.tscn"
export(String) var SceneOptions = "res://assets/UI/Options.tscn"
const MultiplayerToLoad = "res://lobby.tscn"
# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

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
	var  mScene = preload(MultiplayerToLoad)
	var loads = mScene.instance()
	loads.name = "lobby"
	get_tree().get_root().add_child(loads)


func _on_Options_pressed():
	var Options = ResourceLoader.load(SceneOptions)
	get_tree().get_root().add_child(Options.instance())
