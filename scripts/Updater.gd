extends Control

var request
var server_url = "http://107.173.129.154/moonwards/"
var update_list_found = false
var done_updating = false
var download_queue = []
var next_update = true
var updater_started = false
var updater_enabled = false
var file = File.new()

signal receive_update_message

func _process(delta):
	if not updater_enabled:
		set_process(false)
		return
	GetMD5List()
	if get_tree() != null and not updater_started:
		updater_started = true
		Log("Starting Updater...")
		CheckForUpdates()
		set_process(false)
		if not update_list_found:
			Log("Updater Done")
	elif download_queue.size() == 0:
		set_process(false)
		Log("Updater Done")
		LoadPackages()
		Log("NewContentUI.tscn exists : " + str(ResourceLoader.exists("res://scenes/NewContentUI.tscn")))
	elif next_update:
		Log("Getting update " + download_queue[0])
		next_update = false
		var file = File.new()
		var packed_scene_path = "user://updates/" + download_queue[0]
		
		if file.file_exists(packed_scene_path):
			Log("Packed scene already exists. Skipping download.")
			next_update = true
			download_queue.remove(0)
		else:
			var error = request.request(server_url + download_queue[0])
			if error != OK:
				Log("Error requesting update " + download_queue[0])
				next_update = true
				download_queue.remove(0)

func GetMD5List():
	var directory = Directory.new()
	var dictionary = {}
	if directory.open("res://") == OK:
		directory.list_dir_begin(true, true)
		
		var file_name = directory.get_next()
		while (file_name != ""):
			if directory.current_is_dir():
				GetMD5FromDirectory(file_name + "/", dictionary)
			else:
				dictionary["res://" + file_name] = file.get_md5("res://" + file_name)
				Log("res://" + file_name + " md5= " + file.get_md5("res://" + file_name))
			file_name = directory.get_next()
	return dictionary

func GetMD5FromDirectory(var path, var dictionary):
	var directory = Directory.new()
	if directory.open(path) == OK:
		directory.list_dir_begin(true, true)
		
		var file_name = directory.get_next()
		while (file_name != ""):
			if directory.current_is_dir():
				GetMD5FromDirectory(file_name + "/", dictionary)
			else:
				dictionary["res://" + path + file_name] = file.get_md5("res://" + path + file_name)
				Log("res://" + path + file_name + " md5= " + file.get_md5("res://" + path + file_name))
			file_name = directory.get_next()

func LoadPackages():
	var directory = Directory.new()
	if directory.open("user://updates/") == OK:
		directory.list_dir_begin()
		#Go through the whole updates folder and find the files.
		var file_name = directory.get_next()
		while (file_name != ""):
			#A file has been found.
			if not directory.current_is_dir():
				Log("Found File: " + file_name)
				var split_filename = file_name.split(".")
				#Check if the file is a packed scene we can load.
				if split_filename[split_filename.size() - 1] == "pck":
					#Load the pck file into the project.
					var success = ProjectSettings.load_resource_pack(directory.get_current_dir() + file_name)
					Log("Loading File: " + directory.get_current_dir() + file_name + " success" if success else " unsuccessful")
			file_name = directory.get_next()
	else:
		print("An error occurred when trying to access the path.")

func ReadTestFile():
	var file = File.new()
	
	if file.open("res://_tests/Updater/update_content.txt", File.READ) == OK:
		while not file.eof_reached():
			Log(file.get_line())
	else:
		Log("Failed reading file")

func Log(var text):
	emit_signal("receive_update_message", text)

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
	var directory = Directory.new()
	var packed_scene_path = "user://updates/" + download_queue[0]
	
	if not directory.dir_exists("user://updates/"):
		directory.make_dir("user://updates/")
	
	if response_code != HTTPClient.RESPONSE_OK:
		Log("Received response code " + str(response_code) + ".")
	else:
		file.open(packed_scene_path, File.WRITE)
		file.store_buffer(body)
		file.close()
		Log("Done writing " + "user://updates/" + download_queue[0])
	
	download_queue.remove(0)
	next_update = true

func ReceiveUpdateJSON( result, response_code, headers, body ):
	var json = JSON.parse(body.get_string_from_utf8())
	
	Log("Updates found in json:")
	
	for update in json.result["updates"]:
		Log(update)
		download_queue.append(update)
	
	Log("End of json file.")
	request.disconnect("request_completed", self, "ReceiveUpdateJSON")
	request.connect("request_completed", self, "ReceiveUpdate")
	set_process(true)
	