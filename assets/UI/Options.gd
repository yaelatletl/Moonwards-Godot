extends Control



func _ready():
	pass

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		get_tree().get_root().remove_child(self)
#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
