extends Control

var current_slot = slots.pants

enum slots{
	pants,
	shirt,
	skin,
	hair
}

func _ready():
	$VBoxContainer/UsernameContainer/UsernameTextEdit.text = options.username
	SwitchSlot()
	_on_Gender_item_selected(options.gender)
	$VBoxContainer/Gender.selected = int(options.gender)
	$ViewportContainer/Viewport.size = $ViewportContainer.rect_size

func _on_HuePicker_Hue_Selected(color):
	if current_slot == slots.pants:
		options.pants_color = color
	elif current_slot == slots.shirt:
		options.shirt_color = color
	elif current_slot == slots.skin:
		options.skin_color = color
	elif current_slot == slots.hair:
		options.hair_color = color
	$ViewportContainer/Viewport/AvatarPreview.SetColors(options.pants_color, options.shirt_color, options.skin_color, options.hair_color)

func _on_CfgPlayer_pressed():
	$WindowDialog.popup_centered()

func _on_SaveButton_pressed():
	options.SaveUserSettings()
	UIManager.Back()

func _on_SlotOption_item_selected(ID):
	current_slot = ID
	SwitchSlot()

func SwitchSlot():
	if current_slot == slots.pants:
		$VBoxContainer/HuePicker.color = options.pants_color
	elif current_slot == slots.shirt:
		$VBoxContainer/HuePicker.color = options.shirt_color
	elif current_slot == slots.skin:
		$VBoxContainer/HuePicker.color = options.skin_color
	elif current_slot == slots.hair:
		$VBoxContainer/HuePicker.color = options.hair_color
	$ViewportContainer/Viewport/AvatarPreview.SetColors(options.pants_color, options.shirt_color, options.skin_color, options.hair_color)

func _on_Gender_item_selected(ID):
	options.gender = ID
	$ViewportContainer/Viewport/AvatarPreview.SetGender(options.gender)
	if ID == 0:
		$ViewportContainer/Female.show()
		$ViewportContainer/Male.hide()
	else:
		$ViewportContainer/Female.hide()
		$ViewportContainer/Male.show()
func _on_UsernameTextEdit_text_changed(new_text):
	options.username = new_text
