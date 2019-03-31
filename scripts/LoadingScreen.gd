extends Control

func _ready():
	gamestate.connect("loading_progress", self, "SetProgressBar")
	gamestate.connect("loading_error", self, "LoadingError")
	UIManager.RegisterBaseUI(self)
	UIManager.SetCurrentUI($Control)

func SetProgressBar(var progress):
	$Control/ProgressBar.value = progress

func LoadingError(var message):
	$Control/Label.text += str(message)