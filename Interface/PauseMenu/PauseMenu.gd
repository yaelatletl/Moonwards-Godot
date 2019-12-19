extends CanvasLayer
"""
	PauseMenu Singleton Scene Script
"""

onready var tabs: TabContainer = $"H/T"


var _can_open: bool = false
var _open: bool = false


func _ready() -> void:
	_hide()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("mainmenu_toggle"):
		if _open:
			_hide()
		else:
			_show()


func set_openable(state: bool) -> void:
	_can_open = state


func is_open() -> bool:
	return _open


func _show() -> void:
	_open = true
	for i in get_children():
		if i is Control:
			i.visible = true


func _hide() -> void:
	_open = false
	for i in get_children():
		if i is Control:
			i.visible = false


func _on_bContinue_pressed() -> void:
	_hide()


func _on_bOptions_pressed() -> void:
	tabs.current_tab = 1


func _on_bAbout_pressed() -> void:
	tabs.current_tab = 2


func _on_bQuit_pressed() -> void:
	# TODO: Disconnect from server first
	get_tree().quit()
