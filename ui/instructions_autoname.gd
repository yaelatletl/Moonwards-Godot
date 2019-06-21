extends HBoxContainer

func _ready():
	var text_to_place = ""
	var actions = InputMap.get_action_list(self.name)
	for id in range(0,actions.size()):
		if actions[id] is InputEventKey:
			text_to_place = text_to_place + OS.get_scancode_string(actions[id].scancode)
		if actions.size()-1 > id:
			text_to_place = text_to_place + " or "
	$control.text = text_to_place
