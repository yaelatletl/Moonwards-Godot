extends Spatial

# class member variables go here, for example:
# var a = 2
# var b = "textvar"

func _ready():
	print("===Scene Target")
	print("get_tree: ", get_tree())
	print("current scene: ", get_tree().current_scene)
	print("get node: ", get_tree().current_scene.get_node("Position3D"))
	get_tree().current_scene.print_tree_pretty()

#func _process(delta):
#	# Called every frame. Delta is time since last frame.
#	# Update game logic here.
#	pass
