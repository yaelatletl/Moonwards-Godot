extends Control

export (NodePath)var control_path
var is_active = false
var slide_id

func _ready():
	slide_id = $Label.text
	get_node(control_path).RegisterSlideButton(self)

func SetActive(var active):
	is_active = active
	if is_active:
		$TextureRect.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		$TextureRect.modulate = Color(1.0, 1.0, 1.0, 0.25)

func Clicked(event):
	if event.is_action("left_click"):
		get_node(control_path).GoToSlide($Label.text)
