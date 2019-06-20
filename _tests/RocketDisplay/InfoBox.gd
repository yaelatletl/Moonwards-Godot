extends Spatial

export (NodePath)var control_path
var show_text = false

func OnInput(camera, event, click_position, click_normal, shape_idx):
	breakpoint
	if event.is_action("left_click"):
		show_text = !show_text
		$Icon.visible = !show_text
		$Text.visible = show_text