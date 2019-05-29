extends Tabs



func _on_Button_pressed():
	for action in InputMap.get_actions():
		for member in range(0,InputMap.get_action_list(action).size()):
			if InputMap.get_action_list(action)[member] is InputEventKey:
					Input_Map.save_to_config("input", action, InputMap.get_action_list(action)[member].scancode)