extends Spatial

func print_stats():
	yield(get_tree(), "idle_frame")
	print("tree stats")

func _ready():
	print_stats()
	for a in InputMap.get_actions():
		print("action(%s): " % a, InputMap.get_action_list(a))
	
func _input(event):
	if event.is_action_type() and event.is_class("InputEventKey"):
		print(event)
		print("scancode : %s, pressed: %s" % [event.scancode, event.is_pressed()])
		for a in InputMap.get_actions():
			if InputMap.action_has_event(a, event):
				print("event: %s" % a)
		print("end")
