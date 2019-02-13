extends Control

export(NodePath) var source_xyz = "Camera"

func findACamera():
	pass

func _process(delta):
	$Panel/FPS.text = str(Performance.get_monitor(Performance.TIME_FPS))
	$Panel/Objects.text = str(Performance.get_monitor(Performance.RENDER_OBJECTS_IN_FRAME))
	$Panel/Vertices.text = str(Performance.get_monitor(Performance.RENDER_VERTICES_IN_FRAME))
	$Panel/VRAM.text = str(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED))
	
	if self.has_node(source_xyz):
		var xyz = self.get_node(source_xyz)
		
		if xyz :
			var ORIGIN = xyz.to_global(xyz.transform.origin) #Don't change this line or the coordinates won't work if camera is child of moving object (player)
			$Panel/x.text = str(ORIGIN.x)
			$Panel/y.text = str(ORIGIN.y)
			$Panel/z.text = str(ORIGIN.z)
	else:
		var root = get_tree().current_scene
		var cameras = utils.get_nodes_type(root, "Camera", true)
		print("**********", cameras)
		for p in cameras:
			var cam = root.get_node(p)
			print(p, " ", cam.current)
			if cam.current:
				source_xyz = self.get_path_to(cam)
				break

