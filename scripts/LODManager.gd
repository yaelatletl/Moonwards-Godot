extends Node

export(float) var grid_step = 10

var camera = null
var camera_position = Vector3()
var mesh_collection = []

func _ready():
	get_tree().connect("node_added", self, "NodeAddedToTree")
	yield(get_tree(), "idle_frame")
	GetMeshInstances(get_parent(), mesh_collection)
	camera = get_tree().root.get_viewport().get_camera()
	
	if mesh_collection.empty():
		queue_free()
	else:
		yield(get_tree(), "idle_frame")
		UpdateLOD()

func GetMeshInstances(var starting_node, var collection):
	for child in starting_node.get_children():
		if child is MeshInstance and (child.lod_min_distance != 0.0 or child.lod_max_distance != 0.0):
			collection.append(weakref(child))
		GetMeshInstances(child, collection)

func _process(delta):
	if camera == null:
		return

	var new_position = camera.global_transform.origin
	if new_position.distance_to(camera_position) > grid_step:
		UpdateLOD()
		camera_position = new_position

func NodeAddedToTree(var node):
	GetMeshInstances(node, mesh_collection)

func UpdateLOD():
	print("LODManager update, collection size %s, position %s" %  [mesh_collection.size(), camera_position])
	for ref in mesh_collection:
		var mesh = ref.get_ref()
		if mesh == null:
			mesh_collection.erase(ref)
			continue
		var distance_to_camera = mesh.global_transform.origin.distance_to(camera_position)
		var new_visible = false
		if distance_to_camera >= mesh.lod_min_distance and (distance_to_camera < mesh.lod_max_distance or mesh.lod_max_distance == 0.0):
			new_visible = true

		var change_state = "-"
		if mesh.visible and not new_visible:
			change_state = "+"
		elif not mesh.visible and new_visible:
			change_state = "+"
		
		print("mesh(%s), %s distance(%s) visible(%s, %s) %s %s" % [mesh, change_state, distance_to_camera, mesh.visible, new_visible, mesh.lod_min_distance, mesh.lod_max_distance])

		if mesh.visible and not new_visible:
			mesh.visible = false
		elif not mesh.visible and new_visible:
			mesh.visible = true
