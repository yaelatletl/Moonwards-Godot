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
func _ready() -> void:
	print("option control ready")
	t_Areas.pressed = options.get("dev", "enable_areas_lod")
	t_CollisionShapes.pressed = options.get("dev", "enable_collision_shapes")
	t_FPSLimit.pressed = options.get("dev", "3FPSlimit")
	s_FPSLimit.value = options.get("dev", "3FPSlimit_value")
	s_FPSLimit.connect("changed", self, "set_fps_limit")
	t_decimate.pressed = options.get("dev", "hide_meshes_random")
	t_decimate_percent.value = options.get("dev", "decimate_percent")
	t_decimate_percent.connect("changed", self, "set_decimate_percent")
	
	t_Lod_Manager.pressed = options.get("dev", "TreeManager")
	s_HBoxAspect.value = options.get("LOD", "lod_aspect_ratio")
	s_HBoxAspect.connect("changed", self, "set_lod_aspect_ratio")
 
	t_PMonitor.pressed = options.get("_state_", "perf_mon", false)
	
	
	init_playerspeed_control(s_PlayerSpeed)
	
	for i in range(options.fly_cameras.size()):
		t_flycam.add_item(options.fly_cameras[i].label, i)
	t_flycam.button.selected = options.get("dev", "flycamera", 0)
	t_flycam.connect("changed", self, "set_fly_camera")


func get_tab_index() -> int:
	return $TabContainer.current_tab

func set_tab_index(index : int) -> void:
	$TabContainer.current_tab = index

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

func init_playerspeed_control(button : Button) -> void:
	var player = get_player()
	if player:
		button.enabled = true
		button.value = player.get("SPEED_SCALE")
		button.connect("changed", self, "set_player_speed")
		print("found player", player, "at", player.get_path(), ", enable speed changes")
	else:
		button.enabled = false
		button.value = 0

func set_player_speed(value: float) -> void:
	var player = get_player()
	if player:
		player.set("SPEED_SCALE", value)
		print("set_player_speed to value : ", value)

func _on_tAreas_pressed() -> void:
	var button = $TabContainer/Dev/VBoxContainer/tAreas
	debug.e_area_lod(button.pressed)
	options.set("dev", button.pressed, "enable_areas_lod")

func _on_tCollisionShapes_pressed() -> void:
	var button = $TabContainer/Dev/VBoxContainer/tCollisionShapes
	debug.e_collision_shapes(button.pressed)
	options.set("dev", button.pressed, "enable_collision_shapes")

func _on_tFPSLim_pressed() -> void:
	var button = $TabContainer/Dev/VBoxContainer/tFPSLim
	var button2 = $TabContainer/Dev/VBoxContainer/sFPSLim
	debug.set_3fps(button.pressed, button2.value)
	options.set("dev", button.pressed, "3FPSlimit")

func set_fps_limit(value : int) -> void:
	options.set("dev", value, "3FPSlimit_value")
	var button = $TabContainer/Dev/VBoxContainer/tFPSLim
	debug.set_3fps(button.pressed, value)

func _on_tDecimate_pressed() -> void:
	var dp = options.get("dev", "decimate_percent", 90)
	var button = $TabContainer/Dev/VBoxContainer/tDecimate
	if button.pressed:
		debug.hide_nodes_random(dp)
	else:
		debug.hide_nodes_random(0)
	options.set("dev", button.pressed, "hide_meshes_random")

func _on_Exit_pressed() -> void:
	UIManager.Back()

func _on_tPMonitor_pressed() -> void:
	var button = $TabContainer/Dev/VBoxContainer/tPMonitor
	options.set("dev", button.pressed, "show_performance_monitor")
	debug.show_performance_monitor(button.pressed)

func set_decimate_percent(value : int) -> void:
	options.set("dev", value, "decimate_percent")
	if options.get("dev", "hide_meshes_random", false):
		debug.hide_nodes_random(0)
		debug.hide_nodes_random(value)

func set_lod_aspect_ratio(value) -> void:
	options.set("LOD", value, "lod_aspect_ratio")
	var lmp = options.get("_state_", "set_lod_manager")
	if lmp:
		var root = get_tree().current_scene
		root.get_node(lmp).lod_aspect_ratio = value

func _on_tLodManager_pressed() -> void:
	var button = $TabContainer/Dev/VBoxContainer/tLodManager
	options.set("dev", button.pressed, "TreeManager")
	debug.set_lod_manager(button.pressed)

func set_fly_camera(value : int) -> void:
	options.set("dev", value, "flycamera")
