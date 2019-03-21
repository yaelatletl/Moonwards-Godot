extends Node

export(float) var grid_step = 10
export(bool) var enabled = true setget lod_enable
export(NodePath) var scene_path

var id = "LodManager"
var camera = null
var camera_position = Vector3()
var mesh_collection = []
var id_collection = {}

export(bool) var debug = false
func printd(s):
	if debug:
		print(s)

func _ready():
	print("LodManager _ready, enabled(%s)" % enabled)
	if enabled:
		enabled = false
		lod_enable(true)

func lod_enable(turn_on):
	print("LodManager, lod_enable: %s %s" % [turn_on, enabled])
	if turn_on and not enabled:
		print("Enable LodManager, at %s" % get_lodroot().get_path())
		if get_tree():
			get_tree().connect("node_added", self, "NodeAddedToTree")
			enabled = true
			reset()
		else:
			print("Failed to enable lod manager, get_tree is null")
	elif not turn_on and enabled:
		print("Disable LodManager")
		if get_tree():
			get_tree().disconnect("node_added", self, "NodeAddedToTree")
		enabled = false
		reset(false)

func get_lodroot():
	if scene_path:
		return get_node(scene_path)
	else:
		return get_parent()

func reset(init=true):
	print("LodManager reset")
	camera = null
	camera_position = Vector3()
	if mesh_collection.size() > 0:
		print("Restore state")
		for ref in mesh_collection:
			var obj = ref.get_ref()
			var id = obj.get_instance_id()
			printd("%s %s %s %s" % [id, obj.get_path(), obj.visible, id_collection[id].visible])
			if id_collection.has(id) and obj.visible != id_collection[id].visible:
				obj.visible = id_collection[id].visible
	
	mesh_collection = []
	id_collection = {}
	if init:
		init_scene()

func init_scene():
	yield(get_tree(), "idle_frame")
	GetMeshInstances(get_lodroot(), mesh_collection)
	camera = get_tree().root.get_viewport().get_camera()
	
	yield(get_tree(), "idle_frame")
	UpdateLOD()

func GetMeshInstances(var starting_node, var collection):
	#consider that starting_nodes can be object of managment as well
	var sid = starting_node.get_instance_id()
	var nodes = starting_node.get_children()
	nodes.append(starting_node)
	for child in nodes:
		var id = child.get_instance_id()
		if child is MeshInstance and (child.lod_min_distance != 0.0 or child.lod_max_distance != 0.0):
			if not id_collection.has(id):
				collection.append(weakref(child))
				id_collection[id] = {
					visible = child.visible
					}
		if id != sid:
			GetMeshInstances(child, collection)

func _process(delta):
	if not enabled:
		return
	camera = get_tree().root.get_viewport().get_camera()
	if camera == null:
		return

	var new_position = camera.global_transform.origin
	if new_position.distance_to(camera_position) > grid_step:
		UpdateLOD()
		camera_position = new_position

func NodeAddedToTree(var node):
	if get_lodroot().is_a_parent_of(node):
		GetMeshInstances(node, mesh_collection)

func UpdateLOD():
	print("LODManager update, collection size %s, position %s" %  [mesh_collection.size(), camera_position])
	var changes = 0
	var visible = 0
	var hidden = 0
	for ref in mesh_collection:
		var mesh = ref.get_ref()
		if mesh == null:
			mesh_collection.erase(ref)
			continue
		var distance_to_camera = mesh.global_transform.origin.distance_to(camera_position)
		var new_visible = false
		if distance_to_camera >= mesh.lod_min_distance and (distance_to_camera < mesh.lod_max_distance or mesh.lod_max_distance == 0.0):
			new_visible = true

		if mesh.visible and not new_visible:
			changes += 1
		elif not mesh.visible and new_visible:
			changes += 1
		
		#printd("mesh(%s), %s distance(%s) visible(%s, %s) %s %s" % [mesh, change_state, distance_to_camera, mesh.visible, new_visible, mesh.lod_min_distance, mesh.lod_max_distance])

		if mesh.visible and not new_visible:
			mesh.visible = false
		elif not mesh.visible and new_visible:
			mesh.visible = true
		if mesh.visible:
			visible += 1
		else:
			hidden += 1
	
	print("changes(%s), visible(%s), hidden(%s)" % [changes, visible, hidden])
