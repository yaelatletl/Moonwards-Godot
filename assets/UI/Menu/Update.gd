extends WindowDialog
var has_update = true
func _ready():
	pass # Replace with function body.

func _on_Change_log_pressed():
	$Change_log.popup_centered()

func _on_Update_check_pressed():
	$UpdatingUI.popup_centered()


func _on_Change_log_confirmed():
	$Change_log.hide()


func _on_Button_pressed():
	popup_centered()


func _on_button_pressed():
	popup_centered()
