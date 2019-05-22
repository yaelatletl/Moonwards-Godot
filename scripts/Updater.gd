extends Control

var updater_enabled = false

var file = File.new()
var thread = Thread.new()

var tree_md5_list
var tree_md5id

var md5_list_id
var SERVER_PORT = 8000
var MAX_PLAYERS = 32
var SERVER_IP = "127.0.0.1"
var peer
var client_ids = []
var client_id

#upate client paramteres
var client_wait_timeout = 10 #seconds to wait

signal receive_update_message
signal update_ready

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
	tree_md5_list = GetMD5List()
	tree_md5id = GetMD5id(tree_md5_list)
	## remove old updates here##
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

	Log("Get tree checksum")
	tree_md5_list = GetMD5List() #TODO cache that, until next update
	tree_md5id = GetMD5id(tree_md5_list)
	
	#Connect all the function so they can be handled by the client.
	get_tree().connect("connected_to_server", self, "ClientConnectedOK")
	get_tree().connect("connection_failed", self, "ClientConnectedFailed")
	get_tree().connect("server_disconnected", self, "ClientDisconnectedByServer")
	
	peer = NetworkedMultiplayerENet.new()
	var error = peer.create_client(SERVER_IP, SERVER_PORT)
		
	get_tree().set_network_peer(peer)
	
	Log("Connect to server. " + "Error code : " + str(error))

func ClientConnectedOK():
	Log("Connected OK.")
	ClientCheckUpdate()
	#ClientSendMd5List()

func ClientConnectedFailed():
	Log("Connected Failed.")

func ClientDisconnectedByServer():
	Log("The server disconnected.")

func ClientCheckUpdate():
	rpc_id(1, "ServerReceiveMD5id", get_tree().get_network_unique_id(), tree_md5id)

func ClientWaitForUpdate():
	Log("wait for update")
	yield(get_tree().create_timer(client_wait_timeout), "timeout")
	ClientCheckUpdate()

remote func ClientCheckUpdateResult(result):
	match result:
		"list":
			Log("Send md5 list to server")
			ClientSendMd5List()
		"current":
			Log("No update needed")
		"wait":
			Log("Server asks to wait")
			ClientWaitForUpdate()
		"update":
			Log("Server ready to send update")
			rpc_id(1, "ServerSendUpdate", get_tree().get_network_unique_id(), tree_md5id)
		"restart":
			Log("Server says restart update process")
		_:
			Log("unknown response, (%s)" % result)

func upt_name(client_id, server_id=null):
	if server_id == null:
		server_id = tree_md5id
	#_paranoya here_ sanity check for ids should be probably here
	var fname = "user://update_cache/update_%s_%s.pck" % [server_id, client_id.md5_text()]
	return fname

func upt_exists(client_id, server_id):
	var fname = upt_name(client_id, server_id)
	var dir = Directory.new()
	
	return dir.file_exists(fname)

func upt_create(opt):
	var client_id = opt[0]
	var server_id = opt[1]
	var md5_list = opt[2]

	var file = File.new()
	
	var updated_files = {}
	var delete_files = []
	for key in tree_md5_list:
		#Check if the client has the file.
		if not md5_list.has(key):
			updated_files[key] = tree_md5_list[key]
# 			Log("New file found " + tree_md5_list[key] + " md5 : " + key)
# 			printd("New file found " + tree_md5_list[key] + " md5 : " + key)
	
	if updated_files.empty():
		Log("No new files found!")
		return
# 	else:
# # 		Log("Found " + str(updated_files.size()) + " updates.")
# 	
	var packer = PCKPacker.new()
	var directory = Directory.new()
	var package_path = upt_name(client_id)
	
	printd("make update: %s" % package_path)
	#The server writes to a different directory so it doesn't conflict with the client update directory.
	if not directory.dir_exists("user://update_cache/"):
		directory.make_dir("user://update_cache/")
	
	packer.pck_start(package_path, 4)
	
	for key in updated_files:
		var split_asset_name = updated_files[key].split("/")
		var asset_name = split_asset_name[split_asset_name.size() - 1]
# 		Log("Adding file : %s, asset(%s)" % [updated_files[key], asset_name])
# 		packer.add_file(updated_files[key], asset_name)
		packer.add_file(updated_files[key], updated_files[key])
	
	packer.flush(true)
	printd("make update done: %s" % package_path)
	emit_signal("update_ready", client_id)

func upt_get_ignore_files(src_list, dest_list):
	#md5lists, find files which client should not include in generation of md5sum
	#deleted removed files loaded from previous packages
	pass


remote func ServerReceiveMD5id(var client_id, var md5id):
	Log("Recieve client tree id : %s, current id is %s" % [md5id, tree_md5id])
	if md5id == tree_md5id:
		rpc_id(client_id, "ClientCheckUpdateResult", "current")
	elif upt_exists(md5id, tree_md5id):
		Log("Update for client exist, ready to send")
		rpc_id(client_id, "ClientCheckUpdateResult", "update")
	else:
		if thread.is_active():
			rpc_id(client_id, "ClientCheckUpdateResult", "wait")
			Log("already making update package, send wait to client")
		else:
			rpc_id(client_id, "ClientCheckUpdateResult", "list")

func ClientSendMd5List():
	Log("Sending md5 list...")
	#The server always has the id 1. So just send it to id 1 without sending it to the other clients.
	rpc_id(1, "ServerReceiveMD5List", get_tree().get_network_unique_id(), tree_md5_list, tree_md5id)

remote func ServerReceiveMD5List(var client_id, var md5_list, var md5_id):
	Log("Server received md5 list.")
	Log("Client list contains %s entries" % md5_list.size())
	Log("Server list contains %s entries" % tree_md5_list.size())
	
	rpc_id(client_id, "ClientCheckUpdateResult", "wait")
	Log("Start making update, thread")
	thread.start(self, "upt_create", [md5_id, tree_md5id, md5_list])

remote func ServerSendUpdate(var client_id, var md5_id):
	if not upt_exists(md5_id, tree_md5id):
		#some mistake happened
		Log("Client requesting nonexisting update, %s" % md5_id)
		rpc_id(client_id, "ClientCheckUpdateResult", "restart")
	
	var package_path = upt_name(md5_id)
	Log("Sending update package, %s" % package_path)
	file.open(package_path, File.READ)
	var buffer = file.get_buffer(file.get_len())
	rpc_id(client_id, "ClientReceiveUpdate", buffer)
	file.close()
	Log("Update sent")

func GetMD5id(dict):
	var join = ""
	var k = dict.keys()
	k.sort()
	printd("get md5id, dict size %s" % k.size())
	
	for s in k:
		join += s
	return join.md5_text()

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
	GetMD5FromDirectory(path, dictionary)
	Log("GetMD5List total list of files %s" % dictionary.size())
	return dictionary

func GetMD5FromDirectory(var path, var dictionary):
# #debug
	if dictionary.size() > 50:
		return

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
