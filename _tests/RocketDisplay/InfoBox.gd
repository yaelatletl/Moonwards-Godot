extends Spatial

export (String, MULTILINE)var text
export (NodePath)var control_path
var show_text = false

func _ready():
	$Text/Viewport/InfoBoxContent.info_box_controller = self
	self.visible = true
	$Text/Viewport/InfoBoxContent/Label.text = text
	$Icon.visible = !show_text
	$Text.visible = show_text
	get_node(control_path).RegisterInfoBox(self)

func OnInput(camera, event, click_position, click_normal, shape_idx):
	if event.is_action_pressed("left_click"):
		ToggleVisible()

func ToggleVisible():
	show_text = !show_text
	$Icon.visible = !show_text
	$Text.visible = show_text