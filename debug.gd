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
