extends Node

var mesh setget set_mesh, get_mesh
var mesh_info = {}
var mesh_cache = {}
var root

export(bool) var debug = false
func printd(s):
	if debug:
		print(s)

func cache_vars(id=null):
	if id == null and mesh != null:
		id = id_mesh(mesh)
		mesh_cache[id] = mesh_info
		return
	
	if id and mesh_cache.has(id):
		mesh_info = mesh_cache[id]
		#print("cache_vars hit %s" % id)
	else:
		mesh_info = {}

func reset_vars():
	mesh_info = {}

func set_mesh(obj):
	if obj == null:
		print("set_mesh, obj == null")
		return
	if root == null:
		print("scene tree is not defined")
	
	cache_vars()
	mesh = null
	if obj is String or obj is NodePath:
		obj = root.get_node(obj)
		if obj == null:
			return
	if obj is MeshInstance:
		mesh = obj.mesh
	if obj is Mesh:
		mesh = obj
	cache_vars(id_mesh(mesh))
	#print("MeshTool(%s)" % mesh)

func get_mesh():
	return mesh

func _init(tree=null, obj=null):
	print("MeshTool::init(%s, %s)" % [tree, obj])
	if tree == null:
		if get_tree():
			tree = get_tree().current_scene
	root = tree
	set_mesh(obj)

func get_median():
	if mesh == null:
		return
	if mesh_info.has("vert_median"):
		return mesh_info.vert_median

	var vsum = Vector3(0, 0, 0)
	var count = 0
	for v in mesh.get_faces():
		vsum += v
		count += 1
	
	vsum /= count
	return vsum
	
func get_hitbox():
	if mesh == null:
		print("get_hitbox mesh is null")
		return
	if mesh_info.has("hitbox"):
		return mesh_info.hitbox
	
	var box  #x, -x y, -y, z, -z
	for v in mesh.get_faces():
		if box == null:
			box = [v.x, v.x, v.y, v.y, v.z, v.z]
			continue
		if v.x > box[0]:
			box[0] = v.x
		if v.x < box[1]:
			box[1] = v.x
		if v.y > box[2]:
			box[2] = v.y
		if v.y < box[3]:
			box[3] = v.y
		if v.z > box[4]:
			box[4] = v.z
		if v.z < box[5]:
			box[5] = v.z
	mesh_info["hitbox"] = [Vector3(box[1], box[3], box[5]), Vector3(box[0] - box[1], box[2] - box[3], box[4] - box[5])] 
	return mesh_info["hitbox"]

func hbox_volume():
	var bb = get_hitbox()
	if bb == null:
		return 0
	return bb[1].x*bb[1].y*bb[1].z

func hbox_surface():
	var bb = get_hitbox()
	if bb == null:
		return 0
	var hs = bb[1]
	return 2*hs.x*hs.y+2*hs.x*hs.z + 2*hs.y*hs.z

func hbox_surface_projection():
	return hbox_surface()/6

func hbox_instance():
	var cm = CubeMesh.new()
	var bb = get_hitbox()
	cm.size = bb[1]
	return cm

func id_mesh(mesh_obj=null):
	var obj = mesh
	if mesh_obj != null:
		obj = mesh_obj
	if obj == null:
		print("id_mesh, object is null")
		return null
	if not obj.is_class("Resource"):
		print("id_mesh obj(%s) not a Resource type" % obj)
		return null
	var path = obj.resource_path
	return path.md5_text()
