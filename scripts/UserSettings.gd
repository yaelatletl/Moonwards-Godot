extends Control

var current_slot = slots.pants

enum slots{
	pants,
	shirt,
	skin,
	hair,
	shoes
}

func _ready():
	$VBoxContainer/UsernameContainer/UsernameTextEdit.text = options.username
	$VBoxContainer2/UsernameTextEdit2.text = options.username
	SwitchSlot()
	_on_Gender_item_selected(options.gender)
	$VBoxContainer/Gender.selected = int(options.gender)
	$VBoxContainer2/ViewportContainer/Viewport.size = $VBoxContainer2/ViewportContainer.rect_size

func _on_HuePicker_Hue_Selected(color):
	if current_slot == slots.pants:
		options.pants_color = color
	elif current_slot == slots.shirt:
		options.shirt_color = color
	elif current_slot == slots.skin:
		options.skin_color = color
	elif current_slot == slots.hair:
		options.hair_color = color
	elif current_slot == slots.shoes:
		options.shoes_color = color
	$VBoxContainer2/ViewportContainer/Viewport/AvatarPreview.SetColors(options.pants_color, options.shirt_color, options.skin_color, options.hair_color, options.shoes_color)

func _on_CfgPlayer_pressed():
	$WindowDialog.popup_centered()

func _on_SaveButton_pressed():
	options.SaveUserSettings()
	UIManager.Back()

func _on_SlotOption_item_selected(ID):
	$VBoxContainer2/ViewportContainer/Viewport/AvatarPreview.clean_selected()
	$VBoxContainer2/ViewportContainer/Viewport/AvatarPreview.set_selected(ID)
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
	elif current_slot == slots.shoes:
		$VBoxContainer/HuePicker.color = options.shoes_color
	$VBoxContainer2/ViewportContainer/Viewport/AvatarPreview.SetColors(options.pants_color, options.shirt_color, options.skin_color, options.hair_color, options.shoes_color)

func _on_Gender_item_selected(ID):
	options.gender = ID
	$VBoxContainer2/ViewportContainer/Viewport/AvatarPreview.SetGender(options.gender)
	if ID == 0:
		$VBoxContainer2/ViewportContainer/Female.show()
		$VBoxContainer2/ViewportContainer/Male.hide()
	else:
		$VBoxContainer2/ViewportContainer/Female.hide()
		$VBoxContainer2/ViewportContainer/Male.show()
func _on_UsernameTextEdit_text_changed(new_text):
	options.username = new_text
	$VBoxContainer2/UsernameTextEdit2.text = new_text
func _on_UsernameTextEdit2_text_changed(new_text):
	options.username = new_text
	$VBoxContainer/UsernameContainer/UsernameTextEdit.text = new_text

