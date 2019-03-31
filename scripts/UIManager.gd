extends Node

var ui_history_queue = []
var ui_future_queue = []
var current_ui = null
var on_queued_ui = false
var base_ui = null
var has_ui = false

enum ui_events{
	back,
	create_ui,
	queue_ui,
	set_setting,
	dismiss,
	load_level
}

func _ready():
	gamestate.connect("scene_change", self, "SceneChange")

func SceneChange():
	ui_history_queue.clear()
	ui_future_queue.clear()
	has_ui = false

func CanGoBack():
	return (ui_history_queue.size() > 0)

func Back():
	if not CanGoBack():
		return
	#Delete the current UI before going back.
	if current_ui != null:
		current_ui.queue_free()
	AddPreviousUI()
	
func AddPreviousUI():
	base_ui.add_child(ui_history_queue.front())
	SetCurrentUI(ui_history_queue.pop_front())

func FreeMouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func LockMouse():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func QueueCurrentUI():
	current_ui.get_parent().remove_child(current_ui)
	ui_history_queue.append(current_ui)

func QueueUI(var resource):
	if ui_future_queue.empty() and not on_queued_ui:
		NextUI(resource)
		on_queued_ui = true
	else:
		ui_future_queue.append(resource)

func DismissUI():
	# Continue showing the queued UIs.
	if not ui_future_queue.empty():
		ClearUI()
		SwitchUI(ui_future_queue.pop_back())
		on_queued_ui = true
	# If there are no other UIs queued then go back to the previous UI.
	elif CanGoBack():
		Back()
		on_queued_ui = false
	# When there is no history then the UI can be removed completely.
	else:
		ClearUI()
		LockMouse()
		on_queued_ui = false

func CreateUI(var resource):
	var new_ui = resource.instance()
	return new_ui

func ClearUI():
	has_ui = false
	current_ui.queue_free()
	current_ui = null

func NextUI(var next_ui):
	QueueCurrentUI()
	SwitchUI(next_ui)

func SwitchUI(var next_ui):
	var new_ui = CreateUI(next_ui)
	base_ui.add_child(new_ui)
	SetCurrentUI(new_ui)
	has_ui = true
	FreeMouse()

func RegisterBaseUI(var new_base_ui):
	# The base UI is the upper most Control Node.
	base_ui = new_base_ui

func SetCurrentUI(var new_ui):
	# This Node is used to attach all future UI to.
	current_ui = new_ui

func _input(event):
	if event.is_action_pressed("escape"):
		# When pressing escape the future UI queue is used before going back.
		if not ui_future_queue.empty() and on_queued_ui:
			DismissUI()
		else:
			Back()

func LoadLevel(var resource):
	gamestate.load_level(resource)