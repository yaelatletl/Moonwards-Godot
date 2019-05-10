extends Control

func _ready():
	Updater.connect("receive_update_message", self, "AddLogMessage")

func AddLogMessage(var text):
	if not self.visible:
		self.visible = true
	$VBoxContainer/VBoxContainer/RichTextLabel.text += text + "\n"

func SwitchScene():
	get_tree().change_scene("res://scenes/NewContentUI.tscn")