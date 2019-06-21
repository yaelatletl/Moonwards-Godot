extends Spatial

export (String, MULTILINE)var text
export (NodePath)var control_path
var text_visible = false
var active = false

func _ready():
	$Text/Viewport/InfoBoxContent/Label.text = text

func OnInput(camera, event, click_position, click_normal, shape_idx):
	if active and event.is_action_pressed("left_click"):
		SetTextVisible(!text_visible)

func SetActive(var _active):
	active = _active
	self.visible = active
	SetTextVisible(false)

func SetTextVisible(var _text_visible):
	text_visible = _text_visible
	$Icon.visible = !text_visible
	$Text.visible = text_visible