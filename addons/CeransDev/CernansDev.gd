tool
extends EditorPlugin

signal end_processing
var dock # A class member to hold the dock during the plugin lifecycle

var options = {
	cs_skip_branch = ["cs_none" ],
	cs_skip = [ "cs_manual" ],
	cs_groups = [ "cs", "cs_convex", "floor", "wall"],
	cs_convex = ["cs_convex"],
	cs_trimesh = ["cs", "floor", "wall"],
	bakedlight = {path = "lightmaps", ext = "_bldata.res" }
}

#
# Utilite functions
#
func get_scene():
	return get_editor_interface().get_edited_scene_root()

func array_add(a, b):
	for i in b:
		a.append(i)
	return a

func obj_has_groups(obj, groups):
	var has = false
	for grp in groups:
		if obj.get_groups().has(grp):
			has = true
			break
	return has

func obj_add_col_trimesh(obj):
	obj.create_trimesh_collision()

func obj_add_col_convex(obj):
	obj.create_convex_collision()

func obj_has_col(node):
	var has = false
	for obj in node.get_children():
		if obj.get_class() == "StaticBody":
			has = true
			break
	return has

func bt_connect(event):
	dock.connect(event, self, event)

func get_nodes(root, recurent=false):
	var nodes = []
	var objects = root.get_children()
	while objects.size():
		var obj = objects.pop_front()
		if obj.filename:
			if recurent:
				array_add(objects, obj.get_children())
		else:
			array_add(objects, obj.get_children())
		nodes.append(root.get_path_to(obj))
	return nodes

func get_nodes_type(root, type, recurent=false):
	var nodes = get_nodes(root, recurent)
	var result = []
	for path in nodes:
		if root.get_node(path).get_class() == type :
			result.append(path)
	return result

func res_path_is_local(path):
	return path.get_extension().match("tscn::*")
#
# Signal Processing functions
#
func cs_list(dock):
	print("cs_list")
	print(JSON.print(get_cs_list(get_scene()), "    ", true))
	yield(get_tree().create_timer(0.1), "timeout")
	emit_signal("end_processing")

func cs_make(dock):
	var root = get_scene()
	var meshes = get_cs_list(root)
	for node in meshes.convex:
		obj_add_col_convex(root.get_node(node))
	for node in meshes.trimesh:
		obj_add_col_trimesh(root.get_node(node))
	yield(get_tree().create_timer(0.1), "timeout")
	emit_signal("end_processing")

func cs_delete(dock):
	var root = get_scene()
	var meshes = get_cs_list(root)
	var nodes = []
	array_add(nodes, meshes.convex)
	array_add(nodes, meshes.trimesh)
	for path in nodes:
		var node = root.get_node(path)
		for obj in node.get_children():
			if obj.get_class() == "StaticBody":
				print("free: ", obj)
				obj.queue_free()
	yield(get_tree().create_timer(0.1), "timeout")
	emit_signal("end_processing")

func cs_save(dock):
	yield(get_tree().create_timer(0.1), "timeout")
	emit_signal("end_processing")

var lightscale = {}

func lg_scale(dock):
	var down = true
	var scene 
	var nodes
	if lightscale.has("scene"):
		down = false
		scene = lightscale.scene
		nodes = lightscale.nodes
	else:
		scene = get_scene()
		nodes = get_nodes_type(scene, "OmniLight", true)
		array_add(nodes, get_nodes_type(scene, "SpotLight", true))
	for path in nodes:
		var obj = scene.get_node(path)
		var scale = 1
		if down :
			scale /= 20.0
		else:
			scale *= 20.0
		if obj.get_class() == "OmniLight":
			obj.omni_range = scale * obj.omni_range
		if obj.get_class() == "SpotLight":
			obj.spot_range = scale * obj.spot_range
	if down:
		lightscale["scene"] = scene
		lightscale["nodes"] = nodes
	else:
		lightscale = {}
	yield(get_tree().create_timer(0.1), "timeout")
	emit_signal("end_processing")

var bl_scale_down = true

func bl_scale(dock):
	var scale = 1
	if bl_scale_down:
		scale /= 20.0
	else:
		scale *= 20.0
	var scene = get_scene()
	for path in get_nodes_type(scene, "BakedLightmap", true):
		print("BL: %s" % path)
		var obj = scene.get_node(path)
		obj.bake_extents = scale * obj.bake_extents
	bl_scale_down = not bl_scale_down
	yield(get_tree().create_timer(0.1), "timeout")
	emit_signal("end_processing")


func bl_save(dock):
	#print("bl_save:", dock)
	#yield(get_tree().create_timer(5.0), "timeout")
	#print("bl_save after timeout")
	var root = get_scene()
	var bakednodes = get_nodes_type(root, 'BakedLightmap')
	for path in bakednodes:
		var obj = root.get_node(path)
		#obj.light_data
		#obj.light_data.resource_name
		#obj.light_data.resource_path
		print("data: %s, name: %s, path: %s;" % [obj.light_data, obj.light_data.resource_name, obj.light_data.resource_path])
		var s = root.filename
		var filename = s.trim_prefix(s.get_base_dir()+"/").trim_suffix("."+s.get_extension())
		var id = String(path).hash()
		obj.light_data.resource_name = "%s_%s_%s" % [filename, id, obj.name]
		var name_tosave = "%s/%s/%s_%s%s" % [s.get_base_dir(), options.bakedlight.path, filename, id, options.bakedlight.ext]
		var name_toremove
		var subresource = s.get_extension().match("tscn::*")
		var changed = false
		if res_path_is_local(obj.light_data.resource_path):
			var dir = Directory.new()
			if dir.file_exists(name_tosave):
				var error = dir.remove(name_tosave)
				if error != 0:
					print("faield to remove old file %s Error(%i)" % [name_tosave, error])
		elif name_tosave == obj.light_data.resource_path:
			print("already saved: %s" % name_tosave)
			continue
		else:
			#name_toremove = obj.light_data.resource_path
			#needs to make local to move or it incapsulates some data resources of resource
			print("make(%s) %s to be local and try again" % [path, obj.light_data.resource_path])
			continue
		var dir = Directory.new()
		if not dir.dir_exists(name_tosave.get_base_dir()):
			dir.make_dir_recursive(name_tosave.get_base_dir())
		ResourceSaver.save(name_tosave, obj.light_data)
		print("saved to: %s" % name_tosave)
		obj.light_data.resource_path = name_tosave
		changed = true
		if name_toremove:
			var error = Directory.new().remove(name_toremove)
			if error != 0:
				print("error(%i) while removing file: %s" % [error, name_toremove])
# 		if changed:
# 			get_editor_interface().save_scene()
	yield(get_tree().create_timer(0.1), "timeout")
	emit_signal("end_processing")

func grp_list(dock):
	print("list:", get_editor_interface().get_edited_scene_root())
	var groups = ListGroups([get_editor_interface().get_edited_scene_root()])
	print(JSON.print(groups, "    ", true))
	print(JSON.print(groups.groups, "    ", true))
	print("scenes: ", groups.scenes.keys())
	yield(get_tree().create_timer(0.1), "timeout")
	emit_signal("end_processing")

#
# Sustem events
#

func _ready():
	print("dev plugin ready")
	dock.plugin = self
	bt_connect("lg_scale")
	bt_connect("bl_scale")
	bt_connect("bl_save")
	bt_connect("grp_list")
	bt_connect("cs_list")
	bt_connect("cs_make")
	bt_connect("cs_delete")
	bt_connect("cs_save")

func _enter_tree():
	print("dev plugin enter_tree")

	# Initialization of the plugin goes here
	# First load the dock scene and instance it:
	dock = preload("res://addons/CeransDev/CollisionUI.tscn").instance()

	# Add the loaded scene to the docks:
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, dock)
	# Note that LEFT_UL means the left of the editor, upper-left dock
	dock.Editor = get_editor_interface()
	dock.editorplugin = self

func _exit_tree():
	# Clean-up of the plugin goes here
	# Remove the scene from the docks:
	remove_control_from_docks(dock) # Remove the dock
	dock.free() # Erase the control from the memory

#
# List groups stats
#
func group_add(d, grp):
	if d.has(grp):
		d[grp] += 1
	else:
		d[grp] = 1

func ListGroups(nodes, offset=0, groups = {groups = {}, scenes = {}}, file="_none_"):
	for obj in nodes:
		if obj.filename:
			file = obj.filename
			if groups.scenes.has(file):
				continue
			groups.scenes[file] = {file = file, groups = {}}
		for grp in obj.get_groups():
			group_add(groups.scenes[file].groups, grp)
			group_add(groups.groups, grp)
		ListGroups(obj.get_children(), offset+2, groups, file)
	return groups

func get_cs_list(root):
	var meshes = {
			convex = [],
			trimesh = []
		}
	var objects = root.get_children()
	while objects.size():
		var obj = objects.pop_front()
		if obj_has_groups(obj, options.cs_skip_branch):
			continue
		if obj.filename:
			continue
		if obj.get_child_count():
			array_add(objects, obj.get_children())
		if obj_has_groups(obj, options.cs_skip):
			continue
		if obj_has_groups(obj, options.cs_convex):
			meshes.convex.append(root.get_path_to(obj))
		elif obj_has_groups(obj, options.cs_trimesh):
			meshes.trimesh.append(root.get_path_to(obj))
	return meshes
