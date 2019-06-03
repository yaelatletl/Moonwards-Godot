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
	load_level,
	join_server,
	run_locally,
	exit
}
const ui_events_text = ["back", "create_ui", "queue_ui", "set_setting", "dismiss",
						"load_level", "join_server", "run_locally", "exit" ]
func ui_event_to_text(ui_event):
	var text = "none"
	if ui_events_text.size() - 1  > ui_event:
		text = "unknown ui_event(%s)" % ui_event
	else:
		text = ui_events_text[ui_event]
	return text

func _ready():
	gamestate.connect("scene_change", self, "SceneChange")

func UIEvent(ui_event, resource=null):
	match ui_event:
		ui_events.create_ui:
			NextUI(resource)
		ui_events.queue_ui:
			QueueUI(resource)
		ui_events.back:
			Back()
		ui_events.set_setting:
			SetSetting()
		ui_events.dismiss:
			DismissUI()
		ui_events.load_level:
			LoadLevel(resource)
		ui_events.join_server:
			join_server(resource)
		ui_events.run_locally:
			run_local(resource)
		ui_events.exit:
			Exit()
		_:
			print("UIManager, no action for %s resource(%s)" % [ui_event_to_text(ui_event), resource])

func SetSetting():
	print("**implement me UIManager::SetSetting")

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
	if is_instance_valid(current_ui):
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
	if is_instance_valid(current_ui):
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
		on_queued_ui = false

func CreateUI(var resource):
	if resource is String:
		resource = ResourceLoader.load(resource)
	var new_ui = resource.instance()
	return new_ui

func ClearUI():
	has_ui = false
	current_ui.queue_free()
	current_ui = null
	LockMouse()

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

func RequestFocus():
	if has_ui:
		return false
	else:
		has_ui = true
		return true

func ReleaseFocus():
	has_ui = false

func LoadLevel(var resource):
	gamestate.load_level(resource)

func join_server(scene):
	if scene == null or scene == "":
		scene = options.scenes.default_multiplayer_join_server
	
	var player_data = {
		username = options.get("user_settings", "name", namelist.get_name())
	}
	gamestate.player_register(player_data, true, "avatar") #local player
	gamestate.load_level(scene)
	gamestate.client_server_connect(options.join_server_host)

func run_local(scene):
	if scene == null or scene == "":
		scene = options.scenes.default_run_scene

	var player_data = {
		username = options.get("user_settings", "name", namelist.get_name())
	}
	gamestate.player_register(player_data, true, "avatar_local") #local player
	gamestate.load_level(scene)

func Exit():
	get_tree().quit()