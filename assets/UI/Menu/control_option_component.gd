tool
extends HBoxContainer
export(String) var Label_text = "Default control name"
var reading = false
var current_scancode = null

func _enter_tree():
	$Confirm.get_cancel().connect("pressed",self,"_on_Cancel") 
	#Get the popup cancel button and connect it to _on_cancel
	current_scancode = InputMap.get_action_list(str(name))[0].scancode
	$Label.text = Label_text
	if InputMap.has_action(str(name)):
		get_node("Button").text = OS.get_scancode_string(current_scancode)
		#Get the first action asociated with this input
		get_node("Button").disabled = false

func _unhandled_input(event):
	if event is InputEventKey and reading:
		current_scancode = event.scancode
		get_node("Confirm/CenterContainer/Label2").text = OS.get_scancode_string(current_scancode)
		

func _on_change_control_pressed():
	$Confirm.popup_centered()
	reading = true
	pass # replace with function body


func _on_Popup_confirmed():
	pass # replace with function body

func _on_Cancel():
	reading = false
	pass