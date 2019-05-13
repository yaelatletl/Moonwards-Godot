extends Control

enum slots{
	pants,
	shirt,
	skin,
	hair
}

enum genders{
	female,
	male
}

var username
var gender
var current_slot = slots.pants
var pants_color
var shirt_color
var skin_color 
var hair_color
var savefile_json

func loader():
	var savefile = File.new()
	if not savefile.file_exists("user://settings.save"):
		save()
	
	savefile.open("user://settings.save", File.READ)
	savefile_json = parse_json(savefile.get_as_text())
	savefile.close()
	gender = SafeGetSetting("gender", genders.female)
	username = SafeGetSetting("username", "Player Name")
	
	pants_color = SafeGetColor("pants", Color8(49,4,5,255))
	shirt_color = SafeGetColor("shirt", Color8(87,235,192,255))
	skin_color = SafeGetColor("skin", Color8(150,112,86,255))
	hair_color = SafeGetColor("hair", Color8(0,0,0,255))
	
	$VBoxContainer/UsernameContainer/UsernameTextEdit.text = username
	SwitchSlot()
	$ViewportContainer/Viewport/AvatarPreview.SetGender(gender)
	$VBoxContainer/Gender.selected = gender

func SafeGetColor(var color_name, var default_color):
	if not savefile_json.has(color_name):
		return default_color
	else:
		return Color8(savefile_json[color_name + "R"],savefile_json[color_name + "G"],savefile_json[color_name + "B"],255)

func SafeGetSetting(var setting_name, var default_value):
	if not savefile_json.has(setting_name):
		return default_value
	else:
		return savefile_json[setting_name]

func save():
	var savefile = File.new()
	savefile.open("user://settings.save", File.WRITE)
	var save_dict = {
		
		"username" : username,
		"gender" : gender,
		
		"pantsR" : pants_color.r*255, # Vector3 is not supported by JSON
		"pantsG" : pants_color.g*255,
		"pantsB" : pants_color.b*255,
		
		"shirtR" : shirt_color.r*255,
		"shirtG" : shirt_color.g*255,
		"shirtB" : shirt_color.b*255,
		
		"skinR" : skin_color.r*255,
		"skinG" : skin_color.g*255,
		"skinB" : skin_color.b*255,
		
		"hairR" : hair_color.r*255,
		"hairG" : hair_color.g*255,
		"hairB" : hair_color.b*255,
		
		}
	savefile.store_line(to_json(save_dict))
	savefile.close()

func _ready():
	loader()
	$ViewportContainer/Viewport.size = $ViewportContainer.rect_size

func _on_HuePicker_Hue_Selected(color):
	if current_slot == slots.pants:
		pants_color = color
	elif current_slot == slots.shirt:
		shirt_color = color
	elif current_slot == slots.skin:
		skin_color = color
	elif current_slot == slots.hair:
		hair_color = color
	ApplyHueColor()

func _on_CfgPlayer_pressed():
	$WindowDialog.popup_centered()

func _on_SaveButton_pressed():
	save()
	UIManager.Back()

func _on_SlotOption_item_selected(ID):
	current_slot = ID
	SwitchSlot()

func ApplyHueColor():
	$ViewportContainer/Viewport/AvatarPreview.SetColors(pants_color, shirt_color, skin_color, hair_color)

func SwitchSlot():
	if current_slot == slots.pants:
		$VBoxContainer/HuePicker.color = pants_color
	elif current_slot == slots.shirt:
		$VBoxContainer/HuePicker.color = shirt_color
	elif current_slot == slots.skin:
		$VBoxContainer/HuePicker.color = skin_color
	elif current_slot == slots.hair:
		$VBoxContainer/HuePicker.color = hair_color
	ApplyHueColor()

func _on_Gender_item_selected(ID):
	gender = ID
	$ViewportContainer/Viewport/AvatarPreview.SetGender(gender)

func _on_UsernameTextEdit_text_changed(new_text):
	username = new_text
