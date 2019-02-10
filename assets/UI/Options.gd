extends Control

signal close
var signal_close = false

func _ready():
	print("option control ready")
	pass

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if not signal_close:
			get_tree().get_root().remove_child(self)
		else:
			emit_signal("close")
#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass

func _on_GameState_tab_clicked(tab):
	print("_on_GameState_tab_clicked(tab): ", tab)


func _on_GameState_tab_changed(tab):
	print("_on_GameState_tab_changed(tab): ", tab)


func _on_GameState_tab_hover(tab):
	print("_on_GameState_tab_hover(tab): ", tab)


func _on_VBoxContainer_focus_entered():
	print("func _on_VBoxContainer_focus_entered()")
	pass # replace with function body
