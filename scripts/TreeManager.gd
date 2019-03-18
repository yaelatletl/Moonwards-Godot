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

func hboxsetlod(node, children = true):
	var size = 0
	if node is MeshInstance:
		MeshTool.mesh = node
		size += MeshTool.hbox_surface_projection()
	if children:
		for path in utils.get_nodes(node, true):
			size += hboxsetlod(node.get_node(path), true)
	if node.is_class("MeshInstance") and size > 0:
		# do not set lod if it set manually
		if node.lod_min_distance == 0 and node.lod_max_distance == 0:
			node.lod_max_distance = lod_aspect_ratio * sqrt(size)
			print(node, " lod(%s) aspect(%s) size(%s) " % [node.lod_max_distance, lod_aspect_ratio, size])
	return size

func set_lod_aspect_ratio(value):
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
	print("TreeManagment enable")
	if enable_hboxsetlod:
		hboxsetlod(tree)
	if enable_lodmanager and get_node(LodManager):
		var lm = get_node(LodManager)
		lm.enabled = false
		lm.lod_aspect_ratio = lod_aspect_ratio
		lm.scene_path = lm.get_path_to(tree)
		lm.enabled = true

func disable_managment():
	print("TreeManagment disable")
	if enable_lodmanager and get_node(LodManager):
		var lm = get_node(LodManager)

func init(tree_root=null):
	if tree_root == null:
		if get_tree():
			tree_root = get_tree().current_scene
	tree = tree_root
	if tree:
		MeshTool = scripts.MeshTool.new(tree)
		TreeStats = scripts.TreeStats.new(tree)
		enable_managment()

func _ready():
	if enabled:
		init()

func tm_enable(enable):
	if enable and enabled == null:
		enabled = true
		init()
	if not enable and enabled:
		disable_managment()
		enabled = false
	if enable and not enabled:
		if enable_managment():
			enabled = true
