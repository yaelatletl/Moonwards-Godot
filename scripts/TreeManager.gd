extends Node

var id = "TreeManager"
var enabled setget tm_enable
var tree
export(NodePath) var tree_path

export(bool) var enable_lodmanager = true
export(bool) var enable_areamanager = true
export(bool) var enable_boxmesh = true
export(bool) var enable_hboxsetlod = true #set lod values for lod manager based on hitbox of mesh
export(float) var lod_aspect_ratio = 10  setget set_lod_aspect_ratio #lod set as projection of hitbox * aspect_ratio

export(NodePath) var LodManager
var scripts = {
	MeshTool = preload("res://scripts/MeshTool.gd"),
	TreeStats = preload("res://scripts/TreeStats.gd")
}
var MeshTool
var TreeStats

export(bool) var debug = false
var debug_id = "TreeManager:: "
var debug_list = [
# 	{ enable = true, key = "" }
]
func printd(s):
	if debug:
		if debug_list.size() > 0:
			var found = false
			for dl in debug_list:
				if s.begins_with(dl.key):
					if dl.enable:
						print("***", debug_id, s)
					found = true
					break
			if not found:
				print(debug_id, s)
		else:
			print(debug_id, s)

#Set root path to manage mesh instances below
func set_path():
	pass

# generate id of a tree mased on timestamps of all files
# do not detect runtime generated changes
func tree_id():
	var id
	if TreeStats:
		id = TreeStats.id_tree()
	return id

func _process(delta):
	#check active camera for the positions
	#call all other managers with new position
	pass

var update_tree = false
func track_node_added(node):
	if update_tree:
		return
	if not node is MeshInstance:
		return
	if tree and node:
		if tree.has_node(node.get_path()):
			var root = get_tree()
			root.connect("idle_frame", self, "track_update", [], Node.CONNECT_ONESHOT)
			update_tree = true
			printd("TM track node added, set update, cuz %s in %s" % [node.get_path(), tree.get_path()])

func track_node_removed(node):
	if node is MeshInstance and MeshTool:
		#clear cache
		MeshTool.cache_has_mesh(node, true)
	if not update_tree:
		return
	#parent calulated size may change because of removing child nodes, so react on remove too
	if tree and node:
		if tree.has_node(node.get_path()):
			var root = tree.get_tree()
			root.connect("idle_frame", self, "track_update", [], Node.CONNECT_ONESHOT)
			update_tree = true
			printd("TM track node remove, set update, cuz %s in %s" % [node.get_path(), tree.get_path()])

func track_update():
	update_tree = false
	printd("TM track_update")
	if enable_hboxsetlod:
		printd("TM update hboxsetlod at %s" % tree.get_path())
		hboxsetlod(tree)

func track_changes(enable):
	printd("TM track_changes(%s) at %s" % [enable, tree])
	var root = get_tree()
	if root:
		if enable:
			root.connect("node_added", self, "track_node_added")
			root.connect("node_removed", self, "track_node_removed")
		else:
			root.disconnect("node_added", self, "track_node_added")
			root.disconnect("node_removed", self, "track_node_removed")
	else:
		print("fail to setup tracking changes, enable(%s), but get_tree is null" % enable)

func hboxsetlod_check(node):
	var to_set = false
	if node is MeshInstance:
		if node.lod_min_distance == 0 and node.lod_max_distance == 0:
			to_set = true
		if MeshTool.cache_has_mesh(node):
			to_set = true
	return to_set

func hboxsetlod(node, children = true):
	var size = 0
	if hboxsetlod_check(node):
		MeshTool.mesh = node
		size += MeshTool.hbox_surface_projection()
	if children:
		for child in node.get_children():
			size += hboxsetlod(child, true)
	if size > 0 and hboxsetlod_check(node):
		# do not set lod if it set manually
		var new_lmd = lod_aspect_ratio * sqrt(size)
		# round stuff, as there may be problems like that
		# value rounded in mesh sintance lod
		# old new 4.995999 4.996 path /root/LODTestingTree/@LODMesh@56/Sphere
		# [MeshInstance:1406] lod(4.995999) aspect(10) size(0.2496) 
		# however this one is in reverse
		# old new 288.67514 288.675135 path /root/LODTestingTree/MeshInstance
		# [MeshInstance:1249] lod(288.67514) aspect(10) size(833.333333) 
		# casting to float does not help
		# which is odd
		# TODO
		# comparions needs mostly for being able to print debug changes in sizes
		# so it not necessaly and can be removed later to jsut assing values
		# or track it independantly
		if round(new_lmd*1000) != round(node.lod_max_distance*1000):
			#printd("old new %s %s path %s" % [node.lod_max_distance, new_lmd, node.get_path()])
			node.lod_max_distance = new_lmd
			printd("%s lod(%s) aspect(%s) size(%s) name: %s " % [node, node.lod_max_distance, lod_aspect_ratio, size, node.name])
	return size

func set_lod_aspect_ratio(value):
	printd("TreeManager update lod_aspect_ratio from %s to %s" % [lod_aspect_ratio, value])
	if value > 0:
		lod_aspect_ratio = value
	if not enabled:
		return
	if enable_hboxsetlod:
		hboxsetlod(tree)
		if enable_lodmanager and get_node(LodManager):
			var lm = get_node(LodManager)
			lm.UpdateLOD()

func enable_managment():
	if tree == null:
		print("TreeManagment faield to enable, tree is not set")
		return false
	print("TM TreeManagment enable, tree %s" % tree.get_path())
	if enable_hboxsetlod:
		printd("TM start hboxsetlod at %s" % tree.get_path())
		hboxsetlod(tree)
	if enable_lodmanager and get_node(LodManager):
		var lm = get_node(LodManager)
		printd("found LodManager at %s" % lm.get_path())
		lm.enabled = false
		lm.scene_path = lm.get_path_to(tree)
		lm.enabled = true
	else:
		print("LodManager disabled: %s %s" % [enable_lodmanager, LodManager])
		var lm = get_node(LodManager)
		lm.enabled = false
	track_changes(true)
	return true

func disable_managment():
	print("TreeManagment disable")
	if get_node(LodManager):
		var lm = get_node(LodManager)
		lm.enabled = false
		printd("Disable LodManager %s" % lm.get_path())

	track_changes(false)

func init_tree():
	print("Init Tree manager")
	if tree == null:
		if get_tree():
			tree = get_tree().current_scene
			printd("tree set to get_tree: %s" % tree)
	printd("=tree: %s" % tree)
	if tree:
		printd("Init meshtool and treestats scripts")
		MeshTool = scripts.MeshTool.new(tree)
		TreeStats = scripts.TreeStats.new(tree)

func _ready():
	printd("TreeManager _ready, enabled %s" % enabled)
	if enabled:
		init_tree()
		enable_managment()

func tm_enable(enable):
	printd("Tree manager tm_enable (%s, %s)" % [enable, enabled])
	if tree == null and enable:
		init_tree()
		if tree == null:
			printd("Tree manager can't set tree, disabled")
			enabled = null
			return
		enabled = false
	if tree == null and not enable:
		if enabled == null:
			disable_managment()
			enabled = false
		return

	if enable :
		if not enabled:
			enabled = enable_managment()
	else:
		if enabled:
			disable_managment()
			enabled = false
