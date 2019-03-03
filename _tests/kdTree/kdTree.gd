extends Spatial

var Block = preload("Block.tscn")
var kdTree = preload("kdtree.gd")

func rand_coord(scale):
	return randf() * scale - scale/2

func rand_vector(scale):
	return Vector3(rand_coord(scale), rand_coord(scale), rand_coord(scale))

var varr = []
func instance_block():
	var inst = Block.instance()
	var scale = 100
	var v = rand_vector(scale)
	
	inst.translation = v
	varr.push_back(v)
	$blocks.add_child(inst)

func _ready():
	randomize()
	for i in range(50):
		instance_block()
	
	var kdtree = kdTree.new(varr, ["x", "y", "z"])
	print("kdtree instance ", kdtree)
