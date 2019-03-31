extends Control
var username = ''
var color_global = Color8(0,0,0,255)

func loader():
	var savefile = File.new()
	if not savefile.file_exists("user://settings.save"):
		print("Nothing was saved before")
	else:
		savefile.open("user://settings.save", File.READ)
		var content = parse_json(savefile.get_as_text())
		savefile.close()
		username = content["username"]
		color_global = Color8(content["colorR"],content["colorG"],content["colorB"],255)
		$VBoxContainer/UsernameContainer/UsernameTextEdit.text = username
		$VBoxContainer/HuePicker.color = color_global

func save():
	var savefile = File.new()
	savefile.open("user://settings.save", File.WRITE)
	var save_dict = {

		"username" : username,
		"colorR" : color_global.r*255, # Vector3 is not supported by JSON
		"colorG" : color_global.g*255,
		"colorB" : color_global.b*255,
		}
	savefile.store_line(to_json(save_dict))
	savefile.close()

func _ready():
	loader()
	$ViewportContainer/Viewport.size = $ViewportContainer.rect_size

func _on_HuePicker_Hue_Selected(color):
	$ViewportContainer/Viewport/green_man2.change_color(color)
	color_global = color

func _on_CfgPlayer_pressed():
	$WindowDialog.popup_centered()

func _on_SaveButton_pressed():
	save()
	UIManager.Back()
