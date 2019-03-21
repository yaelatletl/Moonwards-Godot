extends Node
var id

func _input(event):
	#print("debug event: %s" % event)
	if event.is_action_pressed("debug_active_cameras"):
		print_active_cameras()
	if event.is_action_pressed("debug_camera_to_local_player"):
		set_active_camera()
	if event.is_action_pressed("debug_test_rpc"):
		print("call debug remote test")
		rpc("test_remote_call")
	if event.is_action_pressed("debug_force_camera"):
		camera_ready(true)

func _ready():
	randomize()
	id = randi()
	gamestate.connect("scene_change", self, "on_scene_change")
	
	var tree = get_tree()
# 	tree.connect("tree_changed", self, "on_tree_change")
	tree.connect("node_added", self, "on_node_added")
	tree.connect("node_removed", self, "on_node_removed")
#	tree.connect("idle_frame", self, "tree_idle_frame")
	
	debug_apply_options()
	#insert some camera
	camera_ready()

func on_tree_change():
	print("debug treechange")
func on_node_added(node):
	print("dgd added node %s" % node.get_path())
func on_node_removed(node):
	print("node removed: %s" % node)
func tree_idle_frame():
	print("tree idle frame")

func debug_apply_options():
	yield(get_tree(), "idle_frame")
	print("Apply options to new player scene")
	e_collision_shapes(options.get("dev", "enable_collision_shapes"))
	hidden_nodes = []
	if options.get("dev", "hide_meshes_random"):
		hide_nodes_random(options.get("dev", "decimate_percent"))
	set_3fps(options.get("dev", "3FPSlimit"))
	e_area_lod(options.get("dev", "enable_areas_lod"))
	set_lod_manager(options.get("dev", "TreeManager", false))

var camera_ready_path
var camera_ready_oldcamera
func camera_ready(force=false):
	yield(get_tree(), "idle_frame")
	var root = get_tree().current_scene
	if camera_ready_path:
		root.get_node(camera_ready_path).queue_free()
		if camera_ready_oldcamera:
			camera_ready_oldcamera.current = true
		camera_ready_oldcamera = null
		camera_ready_path = null
		return
	
	var active = false
	var camera_ready_oldcamera = get_tree().root.get_viewport().get_camera()
	if camera_ready_oldcamera:
		active = true
	if not active or force:
		var camera = ResourceLoader.load("res://assets/Player/player_flycamera.tscn").instance()
		root.add_child(camera)
		camera_ready_path = root.get_path_to(camera)
		camera.get_node("Camera").current = true
		if active:
			print("sync camera position with old camera")
			camera.translation = camera_ready_oldcamera.translation
		print("debug: added fly camera to scene")
		

func on_scene_change():
	debug_apply_options()

func user_scene_changed():
	#reset scene specific things
	pass


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

func hide_obj_check(root, path):
	var obj = root.get_node(path)
	var hide = true
	if utils.obj_has_groups(obj, utils.cs_options.hide_protect):
		hide = false
	if hide and obj.get_child_count() > 0:
		var nodes = utils.get_nodes_type(obj, "MeshInstance", true)
		for p in nodes:
			if obj.get_node(p).visible:
				hide = false
				break
	return hide


#Hide MeshInstance nodes with a chance defined by probability
var hidden_nodes = []
var hidden_nodes_prob
func hide_nodes_random(probability=null):
	var root = get_tree().current_scene
	if probability == null:
		probability = options.get("decimate", "probability", 80)
	if probability == 0:
		#unhide all nodes
		print("unhide nodes (%s)" % hidden_nodes.size())
		for p in hidden_nodes:
			root.get_node(p).visible = true
		hidden_nodes = []
		hidden_nodes_prob = null
		return
	
	var nodes = utils.get_nodes_type(root, "MeshInstance", true)
	print("hide nodes, total(%s) already hidden(%s) probability(%s)" % [nodes.size(), hidden_nodes.size(), probability])
	if nodes.size() < 1 :
		return
	nodes.shuffle()
	
	for p in nodes:
		if not hidden_nodes.has(p):
			var hide = (randi() % 100 <= probability)
			if hide and hide_obj_check(root, p):
				root.get_node(p).visible = false
				hidden_nodes.append(p)
	print("hide nodes, total(%s) already hidden(%s) probability(%s)" % [nodes.size(), hidden_nodes.size(), probability])

var pf_path
func show_performance_monitor(enable):
	if enable and not pf_path:
		var packedscene = ResourceLoader.load("res://scripts/PerformanceMonitor.tscn")
		var root = get_tree().current_scene
		var pf = packedscene.instance()
		root.add_child(pf)
		pf_path = root.get_path_to(pf)
		options.set("_state_", true, "perf_mon")
	if not enable and pf_path:
		var root = get_tree().current_scene
		var pf = root.get_node(pf_path)
		if pf:
			pf.queue_free()
		pf_path = null
		options.set("_state_", false, "perf_mon")

func set_lod_manager(enable):
	var slm = options.get("_state_", "set_lod_manager")
	var root = get_tree().current_scene
	if slm == null:
		#find if lod manager is present in scene
		print("Look for existing TreeManager")
		for p in utils.get_nodes_type(root, "Node", true):
			var obj = root.get_node(p)
			if obj.script and obj.get("id") and obj.id == "TreeManager":
				slm = p
				options.set("_state_", p, "set_lod_manager")
				print("found TreeManager at %s" % p)
				break
		if enable == null:
			#just find if there is lod manager in the tree
			print("end search for LodManager")
			return
	if slm == null:
		#create/add proper node
		print("Load TreeManager")
		var tm_path = options.get("dev", "lod_manager_path", "res://scripts/TreeManager.tscn")
		var tm = ResourceLoader.load(tm_path)
		tm = tm.instance()
		root.add_child(tm)
		slm = root.get_path_to(tm)
		options.set("_state_", slm, "set_lod_manager")
	
	var tm = root.get_node(slm)
	if options.get("LOD", "lod_aspect_ratio"):
		tm.lod_aspect_ratio = options.get("LOD", "lod_aspect_ratio")
	tm.enabled = enable
