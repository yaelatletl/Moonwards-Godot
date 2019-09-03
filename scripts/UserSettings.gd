extends Control

enum slots{
	pants,
	shirt,
	skin,
	hair,
	shoes
}

var current_slot : int = slots.pants


onready var text_edit1 : Node = $VBoxContainer/UsernameContainer/UsernameTextEdit
onready var text_edit2 : Node = $VBoxContainer2/UsernameTextEdit2
onready var gender_edit : Node = $VBoxContainer/Gender
onready var avatar_preview : Node = $VBoxContainer2/ViewportContainer/Viewport/AvatarPreview
onready var hue_picker : Node = $VBoxContainer/HuePicker
onready var button_containter : Node = $VBoxContainer2/ViewportContainer


func _ready() -> void:
	text_edit1.text = options.username
	text_edit2.text = options.username
	SwitchSlot()
	_on_Gender_item_selected(options.gender)
	gender_edit.selected = int(options.gender)
	button_containter.get_node("Viewport").size = button_containter.rect_size

func _on_HuePicker_Hue_Selected(color : Color) -> void:
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
	avatar_preview.SetColors(options.pants_color, options.shirt_color, options.skin_color, options.hair_color, options.shoes_color)

func _on_CfgPlayer_pressed() -> void:
	$WindowDialog.popup_centered()

func _on_SaveButton_pressed() -> void:
	options.SaveUserSettings()
	UIManager.Back()

func _on_SlotOption_item_selected(ID : int) -> void:
	avatar_preview.clean_selected()
	avatar_preview.set_selected(ID)
	current_slot = ID
	SwitchSlot()

func SwitchSlot() -> void:
	if current_slot == slots.pants:
		hue_picker.color = options.pants_color
	elif current_slot == slots.shirt:
		hue_picker.color = options.shirt_color
	elif current_slot == slots.skin:
		hue_picker.color = options.skin_color
	elif current_slot == slots.hair:
		hue_picker.color = options.hair_color
	elif current_slot == slots.shoes:
		hue_picker.color = options.shoes_color
	avatar_preview.SetColors(options.pants_color, options.shirt_color, options.skin_color, options.hair_color, options.shoes_color)

func _on_Gender_item_selected(ID : int) -> void:
	options.gender = ID
	avatar_preview.SetGender(options.gender)
	if ID == 0:
		button_containter.get_node("Female").show()
		button_containter.get_node("Male").hide()
	else:
		button_containter.get_node("Female").hide()
		button_containter.get_node("Male").show()

func _on_UsernameTextEdit_text_changed(new_text : String) -> void:
	options.username = new_text
	text_edit2.text = new_text

func _on_UsernameTextEdit2_text_changed(new_text : String) -> void:
	options.username = new_text
	text_edit1.text = new_text

