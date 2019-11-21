extends Control

signal close
signal save
var signal_close = false

const id = "Options.gd"

onready var t_Areas = $TabContainer/Dev/VBoxContainer/tAreas
onready var t_CollisionShapes = $TabContainer/Dev/VBoxContainer/tCollisionShapes
onready var t_FPSLimit = $TabContainer/Dev/VBoxContainer/tFPSLim
onready var s_FPSLimit =  $TabContainer/Dev/VBoxContainer/sFPSLim
onready var t_decimate = $TabContainer/Dev/VBoxContainer/tDecimate
onready var t_decimate_percent = $TabContainer/Dev/VBoxContainer/sDecimatePercent
onready var t_Lod_Manager = $TabContainer/Dev/VBoxContainer/tLodManager
onready var s_HBoxAspect = $TabContainer/Dev/VBoxContainer/sHBoxAspect
onready var t_PMonitor = $TabContainer/Dev/VBoxContainer/tPMonitor
onready var s_PlayerSpeed = $TabContainer/Dev/VBoxContainer/sPlayerSpeed
onready var t_flycam = $TabContainer/Dev/VBoxContainer/SelectFlyCamera
onready var tabs = $TabContainer

func _ready() -> void:
	print("option control ready")
	t_Areas.pressed = options.get("dev", "enable_areas_lod", true)
	t_CollisionShapes.pressed = options.get("dev", "enable_collision_shapes", true)
	t_FPSLimit.pressed = options.get("dev", "3FPSlimit", true)
	s_FPSLimit.value = options.get("dev", "3FPSlimit_value", 30)
	s_FPSLimit.connect("changed", self, "set_fps_limit")
	t_decimate.pressed = options.get("dev", "hide_meshes_random", false)
	t_decimate_percent.value = options.get("dev", "decimate_percent", 0)
	t_decimate_percent.connect("changed", self, "set_decimate_percent")
	
	t_Lod_Manager.pressed = options.get("dev", "TreeManager", true)
	s_HBoxAspect.value = options.get("LOD", "lod_aspect_ratio", 2)
	s_HBoxAspect.connect("changed", self, "set_lod_aspect_ratio")
 
	t_PMonitor.pressed = options.get("_state_", "perf_mon", false)
	
	
	init_playerspeed_control(s_PlayerSpeed)
	
	for i in range(options.fly_cameras.size()):
		t_flycam.add_item(options.fly_cameras[i].label, i)
	t_flycam.button.selected = options.get("dev", "flycamera", 0)
	t_flycam.connect("changed", self, "set_fly_camera")



func get_tab_index() -> int:
	return tabs.current_tab

func set_tab_index(index : int) -> void:
	tabs.current_tab = index

func close() -> void:
	options.set("state", $TabContainer.current_tab, "menu_options_tab")
	emit_signal("save")
	if not signal_close:
		get_tree().get_root().remove_child(self)
	else:
		emit_signal("close")



func get_player() -> Spatial:
	var res
	var tree = get_tree()
	var pg = options.player_opt.player_group
	if tree.has_group(pg):
		var player = tree.get_nodes_in_group(pg)[0]
		if player and utils.obj_has_property(player, "SPEED_SCALE"):
			res = player
	return res

func init_playerspeed_control(button : Control) -> void:
	var player = get_player()
	if player:
		button.enabled = true
		button.value = player.get("SPEED_SCALE")
		button.connect("changed", self, "set_player_speed")
		print("found player", player, "at", player.get_path(), ", enable speed changes")
	else:
		button.enabled = false
		button.value = 0

func set_fps_limit(value : int) -> void:
	options.set("dev", value, "3FPSlimit_value")
	debug.set_3fps(t_FPSLimit.pressed, value)
	
func set_decimate_percent(value : int) -> void:
	options.set("dev", value, "decimate_percent")
	if options.get("dev", "hide_meshes_random", false):
		debug.hide_nodes_random(0)
		debug.hide_nodes_random(value)

func set_lod_aspect_ratio(value : int) -> void:
	options.set("LOD", value, "lod_aspect_ratio")
	var lmp = options.get("_state_", "set_lod_manager")
	if lmp:
		var root = get_tree().current_scene
		root.get_node(lmp).lod_aspect_ratio = value

func set_fly_camera(value : int) -> void:
	options.set("dev", value, "flycamera")

func set_player_speed(value: float) -> void:
	var player = get_player()
	if player:
		player.set("SPEED_SCALE", value)
		print("set_player_speed to value : ", value)

func _on_tAreas_pressed() -> void:
	debug.e_area_lod(t_Areas.pressed)
	options.set("dev", t_Areas.pressed, "enable_areas_lod")

func _on_tCollisionShapes_pressed() -> void:
	debug.e_collision_shapes(t_CollisionShapes.pressed)
	options.set("dev", t_CollisionShapes.pressed, "enable_collision_shapes")

func _on_tFPSLim_pressed() -> void:
	debug.set_3fps(t_FPSLimit.pressed, s_FPSLimit.value)
	options.set("dev", t_FPSLimit.pressed, "3FPSlimit")


func _on_tDecimate_pressed() -> void:
	var dp = options.get("dev", "decimate_percent", 90)
	if t_decimate.pressed:
		debug.hide_nodes_random(dp)
	else:
		debug.hide_nodes_random(0)
	options.set("dev", t_decimate.pressed, "hide_meshes_random")

func _on_Exit_pressed() -> void:
	UIManager.Back()

func _on_tPMonitor_pressed() -> void:
	options.set("dev", t_PMonitor.pressed, "show_performance_monitor")
	debug.show_performance_monitor(t_PMonitor.pressed)

func _on_tLodManager_pressed() -> void:
	options.set("dev", t_Lod_Manager.pressed, "TreeManager")
	debug.set_lod_manager(t_Lod_Manager.pressed)


