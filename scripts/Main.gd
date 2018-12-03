extends Control
export(String) var SceneToLoad = preload("res://lobby.tscn")



func _on_Run_pressed():
	$ui/main.hide()
	$ui/loading.show()
	$load_timer.start()

func _on_Timer_timeout():
	var loads = SceneToLoad.instance()
	loads.name = "lobby"
	get_tree().get_root().add_child(loads)


func _on_Help_pressed():
	if $ui/main/pHelp.visible :
		$ui/main/pHelp.hide()
	else:
		$ui/main/pHelp.show()
