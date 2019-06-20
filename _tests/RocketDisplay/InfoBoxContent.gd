extends VBoxContainer

var info_box_controller

func OnInput(event):
	if event.is_action_pressed("left_click"):
		info_box_controller.ToggleVisible()
