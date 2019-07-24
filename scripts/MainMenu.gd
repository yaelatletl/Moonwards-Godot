extends Control
var scripts = {
	Updater = preload("res://update/scripts/Updater.gd")
}
var scenes = {
	UpdateUI = preload("res://assets/UI/Menu/Updating_UI.tscn")
	}

var Updater
var result 

signal Update_finished(result)

func _ready_headless():
	print("Setup headless mode")
	var player_data = options.player_opt("server_bot")
	gamestate.player_register(player_data, true) #local player
	gamestate.server_set_mode()
	var worldscene = options.scenes.default_multiplayer_headless_scene
	gamestate.change_scene(worldscene)

func _ready():
	if utils.feature_check_server():
		_ready_headless()
	else:
		UIManager.RegisterBaseUI(self)
		UIManager.SetCurrentUI($VBoxContainer)
	$UpdateUI.connect("continue_pressed",self,"_on_continue_pressed")
	connect("Update_finished",self,"_on_update_finished")
	if options.get("Update info", "available") == true:
		$VBoxContainer/UI/MainUI/ButtonsContainer/About/UpdateAvailable.show()
		$UpdateUI.queue_free()
	elif options.get("Update info", "available") == null:
		check_for_update()
	elif options.get("Update info", "available") == false:
		check_for_update()


func check_for_update():

	var Progress = $UpdateUI/VBoxContainer/ProgressBar
	Updater = scripts.Updater.new()
	Updater.root_tree = get_tree()
	#UpdateStatus()
	var res = Updater.ui_ClientCheckUpdate()
	
	if res["state"] == "gathering":
		Progress.value = 25
		yield(Updater, "chain_ccu")
		Progress.value = 50
		res = Updater.ui_ClientCheckUpdate()
		Progress.value = 100
		
		match res["update_data"]:
			
			true:
				printd("Update available")
				
				$VBoxContainer/UI/MainUI/ButtonsContainer/About/UpdateAvailable.show()
				
				result = 1
			false:
				$VBoxContainer/UI/MainUI/ButtonsContainer/About/UpdateAvailable.hide()
				printd("No update available")
				
				result = 0
			null:
				
				printd("Error occurred")
				result = -1
				
	printd("end gathering: %s" % res)
	emit_signal("Update_finished", result)
	
	
func _on_update_finished(result):
	var Status = $UpdateUI/VBoxContainer/Status
	if result == 1:
		Status.text = "There's an update available"
		options.set("Update info", true,"available")
	if result == 0:
		Status.text = "There are no updates available"
		options.set("Update info", false,"available")
	if result == -1:
		Status.text = "An error occurred"
		options.set("Update info", null,"available")
	$UpdateUI/VBoxContainer/Button.disabled = false
	var Date = OS.get_datetime()
	options.set("Update info",  str(Date.get("hour")), "hour")
	options.set("Update info",  str(Date.get("minute")), "minute")
	options.set("Update info",  str(Date.get("second")), "second")
	options.set("Update info",  str(Date.get("year")), "year")
	options.set("Update info",  str(Date.get("month")), "month")
	options.set("Update info",  str(Date.get("day")), "day")
	options.save()

func _on_continue_pressed():
	if result == 1:
		$VBoxContainer.show()
		$UpdateUI.queue_free()
		UIManager.NextUI(scenes.UpdateUI)
	else:
		$VBoxContainer.show()
		$UpdateUI.queue_free()

var debug_id = "Main Menu"
func printd(s):
	logg.print_fd(debug_id, s)
	
