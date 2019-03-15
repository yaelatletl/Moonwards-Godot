extends Node

var tree

export(bool) var enable_lodmanager = true
export(bool) var enable_areamanager = true
export(bool) var enable_boxmesh = true
export(bool) var enable_hboxsetlod = true #set lod values for lod manager based on hitbox of mesh
export(float) var lod_aspect_ratio = 10  #lod set as projection of hitbox * aspect_ratio

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
			node.lod_max_distance = lod_aspect_ratio * size
			print(node, " lod(%s) aspect(%s) size(%s) " % [node.lod_max_distance, lod_aspect_ratio, size])
	return size

func enable_managment():
	if enable_hboxsetlod:
		hboxsetlod(tree)
		

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
	init()
