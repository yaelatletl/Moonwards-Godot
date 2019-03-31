extends Control

func _ready():
	UIManager.RegisterBaseUI(self)
	UIManager.SetCurrentUI($VBoxContainer)