extends Spatial

var Block = preload("Block.tscn")
var kdTree = preload("res://scripts/kdTree.gd")

func rand_coord(scale):
	return randf() * scale - scale/2

func rand_vector(scale):
	return Vector3(rand_coord(scale), rand_coord(scale), rand_coord(scale))

func randi_coord(scale):
	return randi() % scale - floor(scale/2)

func randi_vector(scale):
	return Vector3(randi_coord(scale), randi_coord(scale), randi_coord(scale))

var varr = []
func instance_block():
	var inst = Block.instance()
	var scale = 100
	var v = randi_vector(scale)
	
	inst.translation = v
	var vv = {x = v.x, y = v.y, z = v.z, data = inst, location = v}
	varr.push_back(vv)
	$blocks.add_child(inst)

func _ready():
	randomize()
	for i in range(50):
		instance_block()
	
	var kdtree = kdTree.new(varr, ["x", "y", "z"])
	print("varr.size(): ", varr.size())
	print("kdtree instance ", kdtree)
	print("count: ", kdtree.count_all())
	print(kdtree.toJSON())
	print("varr")
	print(varr)
# 	print(kdtree.nearest(kdtree.vec3point(Vector3(0, 0, 0)), 100, 3*2500))
# 	print(kdtree.nearest(kdtree.vec3point(Vector3(0, 0, 0)), 100, 1000))
	var point = kdtree.vec3point(Vector3(0, 0, 0))
	var index = 0
	for node in kdtree.nearest(point, 100, 3*2500):
		print(index, "dist: ", kdtree.metric.call_func(point, node[0]), " ", node)
		index += 1
		
		
	print("1000")
	for node in kdtree.nearest(point, 100, 1000):
		print("dist: ", kdtree.metric.call_func(point, node[0]), " ", node)

	var a = [1,2,3,4,5,6,7,8,9,0]
	var kdtree1 = kdTree.new([], ["x", "y", "z"])
	print(kdtree1.slice(a, 5, 0))
	print(kdtree1.slice(a, 0, 2))
