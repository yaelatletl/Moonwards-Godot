extends Control

export (NodePath)var control_path

func Clicked(event):
	if event.is_action("left_click"):
		get_node(control_path).GoToSlide($Label.text)
