extends Control
var scripts = {
	Updater = preload("res://update/scripts/Updater.gd")
}
var scenes = {
	UpdateUI = preload("res://assets/UI/Menu/Updating_UI.tscn")
	}

var Updater

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
	$PanelContainer.connect("continue_pressed",self,"_on_continue_pressed")
	connect("Update_finished",self,"_on_update_finished")
	check_for_update()
var result 
func check_for_update():

	var Progress = $PanelContainer/VBoxContainer/ProgressBar
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
	var Status = $PanelContainer/VBoxContainer/Status
	if result == 1:
		Status.text = "There's an update available"
	if result == 0:
		Status.text = "No update available"
	if result == -1:
		Status.text = "An error ocurred"
	$PanelContainer/VBoxContainer/Button.disabled = false

func _on_continue_pressed():
	if result == 1:
		UIManager.NextUI(scenes.UpdateUI)
	else:
		$VBoxContainer.show()
		$PanelContainer.queue_free()

var debug_id = "Main Menu"
func printd(s):
	logg.print_fd(debug_id, s)
	
