extends Tabs



func _on_Button_pressed():
	for action in InputMap.get_actions():
		if action is InputEventKey:
			InputMapping.save_to_config("input", action, action.scancode)
