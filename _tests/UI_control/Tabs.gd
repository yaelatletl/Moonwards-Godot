extends Control

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	# Called when the node is added to the scene for the first time.
	# Initialization here
	pass

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass


func _on_TabContainer_tab_changed(tab):
	print("%s %s" % [tab, 1])
	pass # replace with function body


func _on_TabContainer_tab_selected(tab):
	print("%s %s" % [tab, 2])
	pass # replace with function body


func _on_TabContainer_pre_popup_pressed():
	print("%s %s" % ["no", 3])
	pass # replace with function body


func _on_Tabs_tab_hover(tab):
	print("tabs %s" % 1)
	pass # replace with function body


func _on_Tabs_tab_close(tab):
	print("tabs %s" % 2)
	pass # replace with function body


func _on_Tabs_tab_clicked(tab):
	print("tabs %s" % 2)
	pass # replace with function body
