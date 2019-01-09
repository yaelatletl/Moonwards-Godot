extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"
var attached = false
var camerascene = preload("res://_tests/Camera/camera_add/Scene2.tscn")

func _ready():
	get_tree().connect("tree_changed", self, "on_scene_change")

func on_scene_change():
	print("===on_scene_change")
	print("get_tree: ", get_tree())
	print("current scene: ", get_tree().current_scene)

	if get_tree().current_scene :
		var attachpoint = get_tree().current_scene.get_node("Position3D")
		print("get node: ", attachpoint)
		get_tree().current_scene.print_tree_pretty()
		if attachpoint :
			if attached == false:
				attachpoint.add_child(camerascene.instance())
				attached = true
			else:
				print("wait camera")
		#the stuff never happens, as after scene change it loses the conenction to tree
		#as the thing gets unloaded
		#and events get handled by new scene
		#auto loaded nodes do not lose coonection, and catch all scene changes.
	


func _on_Button_pressed():
	get_tree().change_scene("res://_tests/Camera/camera_add/SceneTarget.tscn")
	print("===button1")
	print("get_tree: ", get_tree())
	print("current scene: ", get_tree().current_scene)
	print("get node: ", get_tree().current_scene.get_node("Position3D"))
	get_tree().current_scene.print_tree_pretty()


func _on_Button2_pressed():
	print("===button2")
	print("change scene result %s" % get_tree().change_scene("res://_tests/Camera/camera_add/Scene1.tscn"))
	print("preload camerascene ", camerascene)
	print("get_tree: ", get_tree())
	print("current scene: ", get_tree().current_scene)
	print("get node: ", get_tree().current_scene.get_node("Position3D"))
	get_tree().current_scene.print_tree_pretty()



func _on_Button3_pressed():
	print("===button3")
	print("change scene result %s" % get_tree().change_scene("res://_tests/Camera/camera_add/Scene1.tscn"))
	gamestate.queue_attach("Position3D", "res://_tests/Camera/camera_add/Scene2.tscn")
	
	get_tree().current_scene.print_tree_pretty()
