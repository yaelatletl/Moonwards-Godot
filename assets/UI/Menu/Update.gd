extends PanelContainer
var has_update = true
var set_as_updater = false
var UpdatingUI = "res://assets/UI/Menu/Updating_UI.tscn"
var scripts = {
	Updater = preload("res://update/scripts/Updater.gd")
}
var Updater
func _ready():
	Updater = scripts.Updater.new()
	Updater.root_tree = get_tree()
	Updater.connect("update_to_update", self, "fn_update_to_update")
	yield(get_tree(),"idle_frame")
	yield(get_tree(),"idle_frame")
	_on_Update_check_pressed()

func _on_Change_log_pressed():
	$Change_log.popup_centered()

func _on_Update_check_pressed():
	if has_update and set_as_updater:
		UIManager.NextUI(UpdatingUI)
		return
	Updater.ClientOpenConnection() #just connect
	Updater.ClientCheckForServer() #protocol ping server
	Updater.ClientCheckProtocol()  #check version, here where it can be ok or not
	Updater.ClientCheckForUpdate() #calculates current tree id sends to server and get response if it ok or no
	Updater.ClientCloseConnection() #sort of important, as server has no function to drop user connection
	yield(get_tree(),"idle_frame")
	yield(get_tree(),"idle_frame")
	if has_update:
		set_as_updater = true
		$HBoxContainer2/VBoxContainer3/Update_check.text = "Update"
		fn_update_to_update()


func _on_Change_log_confirmed():
	$Change_log.hide()

func fn_update_to_update():
	var lab = $HBoxContainer2/VBoxContainer3/Version3
	lab.add_color_override("font_color",Color("ffff00"))
	lab.text= "There's an update available!"
	print("Drop connection")
	has_update = true