extends Control

var done_updating = false
var updater_enabled = true
var file = File.new()

var server_md5_list
var SERVER_PORT = 8000
var MAX_PLAYERS = 32
var SERVER_IP = "127.0.0.1"
var peer
var client_ids = []
var client_id

signal receive_update_message

func _process(delta):
	pass

func _ready():
	yield(get_tree(), "idle_frame")
	if not updater_enabled:
		set_process(false)
		return
	Log("Updater enabled")

func RunUpdateServer():
	debug_id = "%sServer" % debug_id
	#Connect all the function so they can be handled by the server.
	get_tree().connect("network_peer_connected", self, "ServerPeerConnected")
	get_tree().connect("network_peer_disconnected", self, "ServerPeerDisconnected")
	
	peer = NetworkedMultiplayerENet.new()
	peer.set_bind_ip(IP.resolve_hostname("localhost", 1))
	var error = peer.create_server(SERVER_PORT, MAX_PLAYERS)
	get_tree().set_network_peer(peer)
	
	Log("Create server. " + "Error code : " + str(error))
	Log("Getting MD5 List...")
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	server_md5_list = GetMD5List()
	Log("Done!")

func ServerPeerConnected(var id):
	Log("Peer connected " + str(id))
	client_ids.append(id)

func ServerPeerDisconnected(var id):
	Log("Peer disconnected " + str(id))

func RunUpdateClient():
	debug_id = "%sClient" % debug_id
	#Load all previous packages so those won't have to be downloaded from the server.
	LoadPackages()
	
	#Connect all the function so they can be handled by the client.
	get_tree().connect("connected_to_server", self, "ClientConnectedOK")
	get_tree().connect("connection_failed", self, "ClientConnectedFailed")
	get_tree().connect("server_disconnected", self, "ClientDisconnectedByServer")
	
	peer = NetworkedMultiplayerENet.new()
	var error = peer.create_client(SERVER_IP, SERVER_PORT)
	if get_tree().is_network_server():
		Log("Tree in server mode")
		
	get_tree().set_network_peer(peer)
	
	Log("Connect to server. " + "Error code : " + str(error))

func ClientConnectedOK():
	Log("Connected OK.")
	ClientSendMd5List()

func ClientConnectedFailed():
	Log("Connected Failed.")

func ClientDisconnectedByServer():
	Log("The server disconnected.")

func ClientSendMd5List():
	Log("Sending md5 list...")
	#The server always has the id 1. So just send it to id 1 without sending it to the other clients.
	rpc_id(1, "ServerReceiveMD5List", get_tree().get_network_unique_id(), GetMD5List())

remote func ServerReceiveMD5List(var client_id, var md5_list):
	Log("Server received md5 list.")
	var file = File.new()
	
	var updated_files = {}
	for key in server_md5_list:
		#Check if the client has the file.
		if not md5_list.has(key):
			updated_files[key] = server_md5_list[key]
			Log("New file found " + server_md5_list[key] + " md5 : " + key)
	
	if updated_files.empty():
		Log("No new files found!")
		return
	else:
		Log("Found " + str(updated_files.size()) + " updates.")
	
	var packer = PCKPacker.new()
	var directory = Directory.new()
	var package_path = "user://update_cache/" + str(client_id) + "_update.pck"
	
	#The server writes to a different directory so it doesn't conflict with the client update directory.
	if not directory.dir_exists("user://update_cache/"):
		directory.make_dir("user://update_cache/")
	
	packer.pck_start(package_path, 4)
	
	for key in updated_files:
		var split_asset_name = updated_files[key].split("/")
		var asset_name = split_asset_name[split_asset_name.size() - 1]
		Log("Adding file : %s, asset(%s)" % [updated_files[key], asset_name])
# 		packer.add_file(updated_files[key], asset_name)
		packer.add_file(updated_files[key], updated_files[key])
	
	packer.flush(true)
	
	Log("Sending update package.")
	file.open(package_path, File.READ)
	var buffer = file.get_buffer(file.get_len())
	rpc_id(client_id, "ClientReceiveUpdate", buffer)
	file.close()
	Log("Sending done. Removing cache.")
	if not options.debug:
		directory.remove(package_path)
	else:
		Log("options.debug is set, do not clean chache package")

remote func ClientReceiveUpdate(var buffer):
	var directory = Directory.new()
	
	if not directory.dir_exists("user://updates/"):
		directory.make_dir("user://updates/")
	
	#This will name the package by number. i.e. 00005.pck
	var nr_packages = 0
	if directory.open("user://updates/") == OK:
		directory.list_dir_begin(true, true)
		var file_name = directory.get_next()
		while (file_name != ""):
			if not directory.current_is_dir():
				nr_packages += 1
			file_name = directory.get_next()
		directory.list_dir_end()
		
		var package_name = str(nr_packages).pad_zeros(5)
		var file = File.new()
		
		Log("Package size : " + str(buffer.size()) + " bytes.")
		Log("Writing update to : user://updates/" + package_name + ".pck")
		#Write the actual package by using the buffer received.
		file.open("user://updates/" + package_name + ".pck", File.WRITE)
		file.store_buffer(buffer)
		file.close()
		Log("Done writing new update package. " + package_name + ".pck")
	else:
		Log("Could not write to user directory.")

func GetMD5List():
	var directory = Directory.new()
	var dictionary = {}
	var path = "res://"
	if directory.open(path) == OK:
		directory.list_dir_begin(true, true)
		
		var file_name = directory.get_next()
		while (file_name != ""):
			file_name = path + file_name
			if directory.current_is_dir():
				file_name += "/"
				Log("GetMD5List dive in: %s" % file_name)
				GetMD5FromDirectory(file_name, dictionary)
			else:
				var file_md5 = "%s" % file.get_md5(file_name)
				dictionary[file_md5] = file_name
				Log("%s md5=%s" % [file_name, file_md5])
			file_name = directory.get_next()
	Log("GetMD5List total list of files %s" % dictionary.size())
	return dictionary

func GetMD5FromDirectory(var path, var dictionary):
	var directory = Directory.new()
	if directory.open(path) == OK:
		Log("GetMD5FromDirectory open %s, cwd(%s)" % [path, directory.get_current_dir()])
		directory.list_dir_begin(true, true)
		
		var file_name = directory.get_next()
		while (file_name != ""):
			file_name = path + file_name
			if directory.current_is_dir():
				file_name += "/"
				Log("GetMD5FromDirectory dive in: %s" % file_name)
				GetMD5FromDirectory(file_name, dictionary)
			else:
				var file_md5 = "%s" % file.get_md5(file_name)
				dictionary[file_md5] = file_name
				Log("%s md5=%s" % [file_name, file_md5])
			file_name = directory.get_next()
	else:
		Log("GetMD5FromDirectory fail to open %s" % path)

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

func Log(var text):
	emit_signal("receive_update_message", text)
	printd(text)

var debug_id = "Updater"
func printd(s):
	logg.print_fd(debug_id, s)
