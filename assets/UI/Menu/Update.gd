extends PanelContainer
var has_update = true
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
	Updater.RunUpdateServer()
	Updater.RunUpdateClient()

func _on_Change_log_pressed():
	$Change_log.popup_centered()

func _on_Update_check_pressed():
	Updater.RunUpdateServer()
	Updater.RunUpdateClient()
	yield(get_tree(),"idle_frame")
	yield(get_tree(),"idle_frame")
	if has_update:
		UIManager.NextUI(UpdatingUI)


func _on_Change_log_confirmed():
	$Change_log.hide()

func fn_update_to_update():
	var lab = $HBoxContainer2/VBoxContainer3/Version3
	lab.custom_colors.font_color = Color("ffff00")
	lab.text= "There's an update available!"
	$VBoxContainer/ClientStatus/StartUpdate.disabled = false
	Updater.ClientCloseConnection()
	has_update = true