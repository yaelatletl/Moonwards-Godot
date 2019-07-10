extends Particles

func _process(delta):
	var focus = get_tree().get_root().get_camera()
	if focus !=null:
		translation = focus.to_global(focus.translation)
