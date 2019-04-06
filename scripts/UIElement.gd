extends Node

export(UIManager.ui_events) var ui_event
export (PackedScene) var resource
export (String) var resource_path

func _ready():
	if resource == null and resource_path != null:
		resource = ResourceLoader.load(resource_path)
	var node = self
	if node is Button:
		self.connect("pressed", self, "ButtonPressed")
	elif node is CheckBox:
		self.connect("toggled", self, "CheckBoxToggled")

func ButtonPressed():
	UIEvent()

func CheckBoxToggled(var value):
	UIEvent()

func CheckBoxToggle(var value):
	UIEvent()

func DropDownChoice(var value):
	UIEvent()

func UIEvent():
	UIManager.UIEvent(ui_event, resource)

