extends Tabs



func _on_Button_pressed():
	for action in InputMap.get_actions():
		if InputMap.get_action_list(action)[0] is InputEventKey:
				Input_Map.save_to_config("input", action, InputMap.get_action_list(action)[0].scancode)
	pass