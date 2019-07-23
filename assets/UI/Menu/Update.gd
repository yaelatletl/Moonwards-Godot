extends PanelContainer
var has_update = false
var set_as_updater = false
var UpdatingUI = "res://assets/UI/Menu/Updating_UI.tscn"
var scripts = {
	Updater = preload("res://update/scripts/Updater.gd")
}
signal update_finished(result)
var Updater
func _ready():
	Updater = scripts.Updater.new()
	Updater.root_tree = get_tree()
	Updater.connect("update_to_update", self, "fn_update_to_update")
	$HBoxContainer2/VBoxContainer3/Version3.text = "Last checked:"
	yield(get_tree(),"idle_frame")
	yield(get_tree(),"idle_frame")
	connect("update_finished",self,"_on_update_finished")


var result 

func check_for_update():
	$HBoxContainer2/VBoxContainer3/Version3.text = "Gathering update information"
	
	
	#UpdateStatus()
	var res = Updater.ui_ClientCheckUpdate()
	
	if res["state"] == "gathering":
		
		yield(Updater, "chain_ccu")
		
		res = Updater.ui_ClientCheckUpdate()
		
		
		match res["update_data"]:
			
			true:
				printd("Update available")
				has_update = true
				$VBoxContainer/UI/MainUI/ButtonsContainer/About/UpdateAvailable.show()
				
				result = 1
			false:
				$VBoxContainer/UI/MainUI/ButtonsContainer/About/UpdateAvailable.hide()
				printd("No update available")
				has_update = false
				result = 0
			null:
				
				printd("Error occurred")
				result = -1
				has_update = false
	printd("end gathering: %s" % res)
	emit_signal("update_finished", result)
	
func _on_update_finished(result):
	var Status = $HBoxContainer2/VBoxContainer3/Version3
	if result == 1:
		Status.text = "There's an update available"
	if result == 0:
		Status.text = "There are no updates available"
	if result == -1:
		Status.text = "An error occurred"
	Status.text += "\nLast checked: "
	var Date = OS.get_datetime()
	var Date_to_store = ""
	Date_to_store += str(Date.get("day"))+"/"+str(Date.get("month"))+"/"+str(Date.get("year"))+" at "
	Date_to_store += str(Date.get("hour"))+":"+str(Date.get("minute"))+":"+str(Date.get("second"))
	Status.text += Date_to_store


func _on_Change_log_pressed():
	$Change_log.popup_centered()

func _on_Update_check_pressed():
	check_for_update()
#	if has_update and set_as_updater:
#		UIManager.NextUI(UpdatingUI)
#		return
#	Updater.ClientOpenConnection() #just connect
#	Updater.ClientCheckForServer() #protocol ping server
#	Updater.ClientCheckProtocol()  #check version, here where it can be ok or not
#	Updater.ClientCheckForUpdate() #calculates current tree id sends to server and get response if it ok or no
#	Updater.ClientCloseConnection() #sort of important, as server has no function to drop user connection
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
	
var  debug_id = "About panel"
func printd(s):
	logg.print_fd(debug_id, s)