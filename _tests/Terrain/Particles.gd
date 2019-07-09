extends Particles

func _process(delta):
	if get_tree().get_root().get_camera()!=null:
		translation = get_tree().get_root().get_camera().translation
