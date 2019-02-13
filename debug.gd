extends Node
var id

func _input(event):
	#print("debug event: %s" % event)
	if event.is_action_pressed("debug_active_cameras"):
		print_active_cameras()
	if event.is_action_pressed("debug_camera_to_local_player"):
		set_active_camera()
	if event.is_action_pressed("debug_test_rpc"):
		print("call deug remote test")
		rpc("test_remote_call")

func _ready():
	randomize()
	id = randi()

func print_active_cameras():
	var root = get_tree().current_scene
	var cameras = utils.get_nodes_type(root, "Camera", true)
	for p in cameras:
		print("%s(%s)" % [p, root.get_node(p).current])

func set_active_camera():
	print("set camera to lcoal player: %s" % gamestate.local_id)
	gamestate.player_local_camera()

remote func test_remote_call():
	print("test_remote_call (%s)" % id)

func set_3fps(enable):
	if enable:
		print("debug set FPS to 3")
		Engine.target_fps = 3
	else:
		print("debug set FPS to 0")
		Engine.target_fps = 0

func e_area_lod(enable=true):
	pass

func e_collision_shapes(enable=true):
	var root = utils.scene
	var cs_objects = utils.get_cs_list_cs(root)
	print("e_collision_shape(enable=%s), found : %s" % [enable, cs_objects.size()])
	for p in cs_objects:
		var obj = root.get_node(p)
		obj.disabled = !enable

#Hide MeshInstance nodes with a chance defined by probability
var hidden_nodes = []
func hide_nodes_random(probability):
	var root = get_tree().current_scene
	if probability == 0:
		#unhide all nodes
		print("unhide nodes (%s)" % hidden_nodes.size())
		for p in hidden_nodes:
			root.get_node(p).visible = true
		hidden_nodes = []
		return
	var nodes = utils.get_nodes_type(root, "MeshInstance", true)
	print("hide nodes, total(%s) already hidden(%s) probability(%s)" % [nodes.size(), hidden_nodes.size(), probability])
	
	for p in nodes:
		if not hidden_nodes.has(p):
			var hide = (randi() % 100 <= probability)
			if hide:
				root.get_node(p).visible = false
				hidden_nodes.append(p)
