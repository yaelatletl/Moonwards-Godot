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

var username = 'Player Name'
var gender = genders.female
var current_slot = slots.pants
var pants_color = Color8(49,4,5,255)
var shirt_color = Color8(87,235,192,255)
var skin_color = Color8(150,112,86,255)
var hair_color = Color8(0,0,0,255)

func loader():
	var savefile = File.new()
	if not savefile.file_exists("user://settings.save"):
		print("Nothing was saved before")
		save()
	
	savefile.open("user://settings.save", File.READ)
	var content = parse_json(savefile.get_as_text())
	savefile.close()
	gender = content["gender"]
	username = content["username"]
	pants_color = Color8(content["pantsR"],content["pantsG"],content["pantsB"],255)
	shirt_color = Color8(content["shirtR"],content["shirtG"],content["shirtB"],255)
	skin_color = Color8(content["skinR"],content["skinG"],content["skinB"],255)
	hair_color = Color8(content["hairR"],content["hairG"],content["hairB"],255)
	$VBoxContainer/UsernameContainer/UsernameTextEdit.text = username
	SwitchSlot()
	$ViewportContainer/Viewport/AvatarPreview.SetGender(gender)
	$VBoxContainer/Gender.selected = gender

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
