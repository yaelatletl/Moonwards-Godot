extends Node

export(UIManager.ui_events) var ui_event
export (PackedScene) var resource

func _ready():
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
	if ui_event == UIManager.ui_events.create_ui:
		UIManager.NextUI(resource)
	elif ui_event == UIManager.ui_events.queue_ui:
		UIManager.QueueUI(resource)
		UIManager.QueueUI(resource)
	elif ui_event == UIManager.ui_events.back:
		UIManager.Back()
	elif ui_event == UIManager.ui_events.set_setting:
		UIManager.SetSetting()
	elif ui_event == UIManager.ui_events.dismiss:
		UIManager.DismissUI()
	elif ui_event == UIManager.ui_events.load_level:
		UIManager.LoadLevel(resource)