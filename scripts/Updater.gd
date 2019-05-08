extends Control

var request
var server_url = "http://107.173.129.154/moonwards/"
var update_list_found = false
var done_updating = false
var download_queue = []
var next_update = true

func _ready():
	AddText("Starting Updater...")
	CheckForUpdates()
	set_process(false)
	if not update_list_found:
		AddText("Updater Done")

func _process(delta):
	if download_queue.size() == 0:
		set_process(false)
		AddText("Updater Done")
		LoadPackages()
		ReadTestFile()
	elif next_update:
		AddText("Getting update " + download_queue[0])
		next_update = false
		var error = request.request(server_url + download_queue[0])
		
		if error != OK:
			AddText("Error requesting update " + download_queue[0])
			next_update = true
			download_queue.remove(0)

func LoadPackages():
	var directory = Directory.new()
	if directory.open("res://updates/") == OK:
		directory.list_dir_begin()
		#Go through the whole updates folder and find the files.
		var file_name = directory.get_next()
		while (file_name != ""):
			#A file has been found.
			if not directory.current_is_dir():
				AddText("Found File: " + file_name)
				var split_filename = file_name.split(".")
				#Check if the file is a packed scene we can load.
				if split_filename[split_filename.size() - 1] == "pck":
					#Load the pck file into the project.
					var success = ProjectSettings.load_resource_pack(directory.get_current_dir() + file_name)
					AddText("Loading File: " + directory.get_current_dir() + file_name + " success" if success else " unsuccessful")
			file_name = directory.get_next()
	else:
		print("An error occurred when trying to access the path.")

func ReadTestFile():
	var file = File.new()
	AddText("Exists : " + str(file.file_exists("res://_tests/Updater/update_001.txt")))
	if file.open("res://_tests/Updater/update_001.txt", File.READ) == OK:
		while not file.eof_reached():
			AddText(file.get_line())
	else:
		AddText("Failed reading file")

func AddText(var text):
	$VBoxContainer/RichTextLabel.text += text + "\n"

func CheckForUpdates():
	request = HTTPRequest.new()
	add_child(request)
	request.connect("request_completed", self, "ReceiveUpdateJSON")
	var error = request.request(server_url + "updates.json")
	
	if error != OK:
		return
	else:
		update_list_found = true

func ReceiveUpdate( result, response_code, headers, body ):
	var file = File.new()
	var packed_scene_path = "res://updates/" + download_queue[0]
	
	if file.file_exists(packed_scene_path):
		AddText("Packed scene already exists. Skipping download.")
	else:
		file.open(packed_scene_path, File.WRITE)
		file.store_buffer(body)
		file.close()
		AddText("Done writing " + "res://updates/" + download_queue[0])
	
	download_queue.remove(0)
	next_update = true

func ReceiveUpdateJSON( result, response_code, headers, body ):
	var json = JSON.parse(body.get_string_from_utf8())
	
	AddText("Updates found in json:")
	
	for update in json.result["updates"]:
		AddText(update)
		download_queue.append(update)
	
	AddText("End of json file.")
	request.disconnect("request_completed", self, "ReceiveUpdateJSON")
	request.connect("request_completed", self, "ReceiveUpdate")
	set_process(true)
	