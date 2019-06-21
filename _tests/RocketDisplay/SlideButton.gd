extends Control

export (NodePath)var control_path
var info_box_class = load("res://_tests/RocketDisplay/InfoBox.gd")
var info_boxes = []
var active = false
export (int) var stage

func _ready():
	for child in get_children():
		if child is info_box_class:
			info_boxes.append(child)
	get_node(control_path).RegisterSlideButton(self)

func SetActive(var _active):
	active = _active
	for info_box in info_boxes:
		info_box.SetActive(active)
	if active:
		$TextureRect.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		$TextureRect.modulate = Color(1.0, 1.0, 1.0, 0.25)

func Clicked(event):
	if event.is_action("left_click"):
		get_node(control_path).GoToSlide($Label.text)