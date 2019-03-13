extends Control

signal close
signal save
var signal_close = false

func get_tab_index():
	return $Panel/TabContainer.current_tab

func set_tab_index(index):
	$Panel/TabContainer.current_tab = index

func close():
	options.set("state", $Panel/TabContainer.current_tab, "menu_options_tab")
	emit_signal("save")
	if not signal_close:
		get_tree().get_root().remove_child(self)
	else:
		emit_signal("close")

func _ready():
	print("option control ready")
	var button
	button = $Panel/TabContainer/Dev/VBoxContainer/tAreas
	button.pressed = options.get("dev", "enable_areas_lod", true)
	button = $Panel/TabContainer/Dev/VBoxContainer/tCollisionShapes
	button.pressed = options.get("dev", "enable_collision_shapes", true)
	button = $Panel/TabContainer/Dev/VBoxContainer/tFPSLim
	button.pressed = options.get("dev", "3FPSlimit", false)
	button = $Panel/TabContainer/Dev/VBoxContainer/tDecimate
	button.pressed = options.get("dev", "hide_meshes_random", false)
	button = $Panel/TabContainer/Dev/VBoxContainer/sDecimatePercent
	button.value = options.get("dev", "hide_meshes_percent", 90)
	
	button = $Panel/TabContainer/Dev/VBoxContainer/tPMonitor
	button.pressed = options.get("_state_", "perf_mon", false)


func _input(event):
	if event.is_action_pressed("ui_cancel"):
		close()

func _on_GameState_tab_clicked(tab):
	print("_on_GameState_tab_clicked(tab): ", tab)


func _on_GameState_tab_changed(tab):
	print("_on_GameState_tab_changed(tab): ", tab)


func _on_GameState_tab_hover(tab):
	print("_on_GameState_tab_hover(tab): ", tab)


func _on_VBoxContainer_focus_entered():
	print("func _on_VBoxContainer_focus_entered()")
	pass # replace with function body


func _on_tAreas_pressed():
	var button = $Panel/TabContainer/Dev/VBoxContainer/tAreas
	debug.e_area_lod(button.pressed)
	options.set("dev", button.pressed, "enable_areas_lod")


func _on_tCollisionShapes_pressed():
	var button = $Panel/TabContainer/Dev/VBoxContainer/tCollisionShapes
	debug.e_collision_shapes(button.pressed)
	options.set("dev", button.pressed, "enable_collision_shapes")


func _on_tFPSLim_pressed():
	var button = $Panel/TabContainer/Dev/VBoxContainer/tFPSLim
	debug.set_3fps(button.pressed)
	options.set("dev", button.pressed, "3FPSlimit")


func _on_tDecimate_pressed():
	var dp = options.get("dev", "decimate_percent", 90)
	var button = $Panel/TabContainer/Dev/VBoxContainer/tDecimate
	if button.pressed:
		debug.hide_nodes_random(dp)
	else:
		debug.hide_nodes_random(0)
	options.set("dev", button.pressed, "hide_meshes_random")


func _on_Exit_pressed():
	close()


func _on_tPMonitor_pressed():
	var button = $Panel/TabContainer/Dev/VBoxContainer/tPMonitor
	options.set("dev", button.pressed, "show_performance_monitor")
	debug.show_performance_monitor(button.pressed)
