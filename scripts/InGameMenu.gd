extends Control

var ui_resource = preload("res://ui/InGameMenuUI.tscn")
var ui_ref = WeakRef.new()

func _ready():
	pass

func _input(event):
	if event.is_action_pressed("escape") and ui_ref.get_ref() == null:
		var ui = ui_resource.instance()
		self.add_child(ui)
		ui_ref = weakref(ui)
		UIManager.RegisterBaseUI(self)
		UIManager.SetCurrentUI(ui)
