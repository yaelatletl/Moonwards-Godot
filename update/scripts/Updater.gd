extends Control

var updater_enabled = true
var upt_debug = false
var root_tree setget set_root_tree #scene tree for set get network sockets

func set_root_tree(value):
	printd("set_root_tree: %s" % value)
	if get_tree() == null:
		if value != null:
			#attach to tree for rpc calls
			root_tree = value
			root_tree.current_scene.add_child(self)
			SetState("attach_tree", weakref(value))
			printd("Updater attached to tree")
		else:
			printd("fail to attach Updater to tree, required for RPC calls")


#var updater_enabled = true
#var upt_debug = true
var protocol_version = "0.1"

const UPDATE_CHUNK_SIZE = 1000000

#client send protocol version
#server checks it and continue or update client message
#client sends tree md5 identification
#server packs an update or inform to be ready to upload existing update package
#server send update info (file lists, size)
#clinet update filter based on update info, which affects tree id creation
#client downloads update package
#load update
#recalculate tree id
#update finished

var file = File.new()
var directory = Directory.new()
#one packing thread
var thread = Thread.new()

var tree_md5_list
var tree_md5id

var SERVER_PORT = 8000
var MAX_PLAYERS = 32
var SERVER_IP = "127.0.0.1"
var peer
var client_ids = {}

var user_updates_path = "user://updates/"
var user_updates_filter = "user://updates/ignore.lst"
var server_updates_path = "user://update_cache" #no slash at the end
var server_package_path = "user://updates_server/"

#############################
# update variables
var update_filter = {
	#basic glob pattern match
	"exclude" : [
		"res://_tests/*",
		"res://_maintance/*",
		"res://addons/CeransDev/*",
		"res://_tests.ignore/*"
	],
	"include" : [
	],
	#basic string match
	"ignore" : [
	]
}

var filter = update_filter

#upate client paramteres
var client_wait_timeout = 10 #seconds to wait
#download update in chunks, fails to load big updates in one chunks
#keep track on current downloading process
var update_status = {
	"role" : null,
	"state" : "tobegin",
	"fh" : null,
	"fhn" : "",
	"target_size" : 0,
	"current_size" : 0
}
# update_status["current_size"]
# update_status["fh"]
# update_status["fhn"]
# update_status["target_size"]


signal receive_update_message
signal update_ready
signal update_progress(percent)
signal update_ok
signal update_fail
signal server_update_done
signal client_update_done

func debug_unknown_status(stat, value):
	printd("unknown_status: %s(%s)" % [stat, value])

#====
signal network_ok
signal network_fail
signal client_protocol(state)
signal server_connected
signal server_disconnected
signal server_fail_connecting
signal server_online
signal server_offline
signal update_no_update
signal update_to_update
# signal update_progress(percent)
signal update_finished
signal error(msg)

func SetState(stat, value):
	if stat == null:
		return
	match stat:
		"role":
			match value:
				"client":
					update_status["role"] = "client"
					debug_id = "UpdaterClient"
					if not directory.dir_exists(user_updates_path):
						directory.make_dir(user_updates_path)
				"server":
					update_status["role"] = "server"
					debug_id = "UpdaterServer"
					if not directory.dir_exists(server_package_path):
						directory.make_dir(server_package_path)
		"server_ping":
			if value:
				emit_signal("server_online")
			else:
				emit_signal("server_offline")
			update_status["server_online"] = value
		"network":
			match value:
				"ok":
					emit_signal("network_ok")
					update_status["network"] = true
				"fail":
					emit_signal("network_fail")
					update_status["network"] = false
					emit_signal("error", "Failed to establish network conenction")
				_:
					debug_unknown_status(stat, value)
		"server":
			match value:
				"fail":
					emit_signal("server_fail_connecting")
					update_status["server_online"] = false
				"connected":
					emit_signal("server_connected")
				"disconnected":
					emit_signal("server_disconnected")
				"online":
					emit_signal("server_online")
					update_status["server_online"] = true
		"protocol":
			match value:
				"match":
					update_status["protocol_version"] = true
					emit_signal("client_protocol", true)
				"invalid":
					update_status["protocol_version"] = false
					emit_signal("client_protocol", false)
		"server_tree_id":
			update_status[stat] = value
			printd("server_tree_id (c,s,comp) %s, %s, %s" % [tree_md5id, value, value == tree_md5id])
			if value != null and tree_md5id != null:
				if value != tree_md5id:
					emit_signal("update_to_update")
				else:
					emit_signal("update_no_update")
		_:
			update_status[stat] = value

func is_network_ok():
	pass
func is_server_online():
	pass
func is_protocol_ok():
	pass
func is_update_client():
	pass
func is_update_data():
	pass

func GetState(stat):
	var res = null
	if stat != null and update_status.has(stat):
		res = update_status[stat]
	return res

func SetState_default():
	update_status = {
			"role" : null,
			"state" : "tobegin",
			"fh" : null,
			"fhn" : "",
			"target_size" : 0,
			"current_size" : 0
		}

func ClientOpenConnection():
	SetState("role", "client")
	#Connect all the function so they can be handled by the client.
	root_tree.connect("connected_to_server", self, "ClientConnectedOK")
	root_tree.connect("connection_failed", self, "ClientConnectedFailed")
	root_tree.connect("server_disconnected", self, "ClientDisconnectedByServer")
	
	peer = NetworkedMultiplayerENet.new()
	var error = peer.create_client(SERVER_IP, SERVER_PORT)
	if error != 0:
		SetState("network", "fail")
	else:
		root_tree.set_network_peer(peer)
		SetState("network", "ok")

func ClientCheckForServer():
	Log("Check server online")
	toServer("ping")

func ClientCheckProtocol():
	Log("Check protocol version")
	toServer("protocol_version", protocol_version)

func ClientCheckForUpdate():
	if tree_md5id == null:
		UpdateTreeID()
	toServer("current_tree_id")

func ClientGetUpdateInfo():
	pass
func ClientStartUpdateProcess():
	pass

func ClientCloseConnection():
	printd("ClientCloseConnection")
	root_tree.set_network_peer(null)
	SetState("server", "disconnected")

func _process(delta):
	pass

func _ready():
	yield(root_tree, "idle_frame")
	if not updater_enabled:
		set_process(false)
		return
	Log("Updater enabled")
	connect("update_ready", self, "thread_active_correction")
	

func toClient(client_id, command, data=null):
	printd("toClient: %s" % command)
	rpc_id(client_id, "UpdateProtocolClient", command, data)
	if command == "abort":
		#close connnection with client, peer initialised in RunUpdateServer
		if peer != null:
			peer.disconnect_peer(client_id)

func toServer(command, data=null):
	printd("toServer: %s" % command)
	rpc_id(1, "UpdateProtocolServer", root_tree.get_network_unique_id(), command, data)

func RunUpdateServer():
	SetState("role", "server")

	LoadPackages(server_package_path, true)
	#Connect all the function so they can be handled by the server.
	root_tree.connect("network_peer_connected", self, "ServerPeerConnected")
	root_tree.connect("network_peer_disconnected", self, "ServerPeerDisconnected")
	
	peer = NetworkedMultiplayerENet.new()
	peer.set_bind_ip(IP.resolve_hostname("localhost", 1))
	var error = peer.create_server(SERVER_PORT, MAX_PLAYERS)
	root_tree.set_network_peer(peer)
	
	Log("Create server. " + "Error code : " + str(error))
	Log("Getting MD5 List...")
	yield(root_tree, "idle_frame")
	yield(root_tree, "idle_frame")
	UpdateTreeID()

	#The server writes to a different directory so it doesn't conflict with the client update directory.
	if not directory.dir_exists(server_updates_path):
		Log("make directory to keep server updates")
		directory.make_dir(server_updates_path)
	## remove old updates here##
	emit_signal("server_update_done")
	Log("Done!")

func ServerPeerConnected(var id):
	Log("Peer connected %s" % id)
	client_ids[id] = {
		"id" : id
		}

func ServerPeerDisconnected(var id):
	Log("Peer disconnected %s" % id)
	client_ids.erase(id)

func RunUpdateClient():
	SetState("role", "client")

	#Load all previous packages so those won't have to be downloaded from the server.
	LoadPackages()

	#load existing ignore list from last update, for tree id generation
	ClientUpdateFilter(upt_info_load())

	Log("Get tree checksum")
	UpdateTreeID()
	
	#Connect all the function so they can be handled by the client.
	root_tree.connect("connected_to_server", self, "ClientConnectedOK")
	root_tree.connect("connection_failed", self, "ClientConnectedFailed")
	root_tree.connect("server_disconnected", self, "ClientDisconnectedByServer")
	
	peer = NetworkedMultiplayerENet.new()
	var error = peer.create_client(SERVER_IP, SERVER_PORT)
		
	root_tree.set_network_peer(peer)
	if error==0:
		emit_signal("client_update_done")
	else:
		Log("Connect to server. " + "Error code : " + str(error))
	

func ClientConnectedOK():
	Log("Connected OK.")
	SetState("server", "connected")
# 	ClientCheckProtocol()

func ClientConnectedFailed():
	Log("Connected Failed.")
# 	SetState("network", "fail")
	SetState("server", "fail")

func ClientDisconnectedByServer():
	Log("The server disconnected.")
	SetState("server", "disconnected")

func ClientWaitForUpdate():
	Log("wait for update")
	yield(root_tree.create_timer(client_wait_timeout), "timeout")
	toServer("tree_id", tree_md5id)

func ClientUpdateInfo(info):
	var size = -1
	if info.has("size"):
		size = info["size"]
	Log("Update size is %s, preparing to download" % size)
	ClientUpdateFilter(info)
	#store total size for downloading
	update_status["target_size"] = size
	update_status["current_size"] = 0
	return size

remote func UpdateProtocolClient(command, data=null):
	match command:
		"pong":
			Log("Server online")
			SetState("server", "online")
		"list":
			Log("Send md5 list to server")
			toServer("tree_list", [tree_md5_list, tree_md5id])
		"current":
			Log("No update needed")
			ClientUpdateEnd(true)
		"current_tree_id":
			Log("Server tree id is : %s" % data)
			SetState("server_tree_id", data)
		"wait":
			Log("Server asks to wait")
			ClientWaitForUpdate()
		"update_info":
			#update filters, and see if there is data to download
			Log("prepare for update, get information about update")
			var size = ClientUpdateInfo(data)
			if size > 0:
				toServer("send_data", tree_md5id)
			else:
				ClientUpdateEnd(true)
			upt_info_save(data)
		"recv_data":
			ClientReceiveUpdate(data)
		"restart":
			Log("Server says restart update process")
			ClientUpdateEnd(false)
		"client_protocol_ok":
			Log("Update protocol correct")
			SetState("protocol", "match")
# 			toServer("tree_id", tree_md5id)
		"client_protocol_mismatch":
			#inform about necessity to update client
			Log("new client needs to be downloaded")
			SetState("protocol", "invalid")
			ClientUpdateEnd(false)
		"abort":
			Log("Update failed, some server error, id %s" % tree_md5id)
			ClientUpdateEnd(false)
		_:
			Log("unknown command/response from server, (%s)" % command)
			ClientUpdateEnd(false)

remote func UpdateProtocolServer(client_id, command, data=null):
	match command:
		"ping":
			toClient(client_id, "pong")
		"protocol_version":
			ServerUpdateProtocol(client_id, data)
		"current_tree_id":
			toClient(client_id, "current_tree_id", tree_md5id)
		"tree_id" :
			ServerReceiveMD5id(client_id, data)
		"tree_list" :
			ServerReceiveMD5List(client_id, data[0], data[1])
		"send_data" :
			ServerSendUpdate(client_id, data)
		_:
			Log("unknown command/response from client, (%s)" % command)
			toClient(client_id, "abort")

func ClientUpdateFilter(info):
	if info == null:
		Log("no update info to process")
		return
	Log("Update files filter list, a/u/r entries %s/%s/%s" % [info["add"].size(), info["update"].size(), info["remove"].size()])
	var add_list = info["add"] + info["update"]
	var ignore_list = info["remove"]
	var ignore = filter["ignore"]
	for p in ignore:
		if add_list.has(p):
			ignore.erase(p)
	if tree_md5_list:
		for p in ignore_list:
			tree_md5_list.erase(p)
		for p in add_list:
			tree_md5_list.erase(p)
	
	filter["ignore"] = filter["ignore"] + ignore_list

func ClientUpdateEnd(sucess):
	if sucess:
		emit_signal("update_ok")
	else:
		emit_signal("update_fail")
	root_tree.set_network_peer(null)

func upt_info_save(info):
	var f = File.new()
	Log("Save new filter list to file %s" % user_updates_filter)
	f.open(user_updates_filter, File.WRITE)
	f.store_var(info)
	f.close()

func upt_info_load():
	var info
	if file.file_exists(user_updates_filter):
		var f = File.new()
		Log("Load filter list from file %s" % user_updates_filter)
		f.open(user_updates_filter, File.READ)
		info = f.get_var()
		f.close()
	return info

func upt_name(client_id, ext="pck", server_id=null):
	if server_id == null:
		server_id = tree_md5id
	#_paranoya here_ sanity check for ids should be probably here
	if not client_id.is_valid_hex_number():
		Log("client id is not a hex_md5")
		client_id = client_id.md5_text()
	var fname = "%s/update_%s_%s.%s" % [server_updates_path, server_id, client_id, ext]
	return fname

func upt_exists(client_id):
	var update_data = upt_name(client_id)
	var result = false
	var info = upt_info(client_id)
	if file.file_exists(update_data):
		result = true
	if info and info["size"] == 0:
		result = true
	return result

func upt_compare_lists(src_list, dest_list):
	#md5lists, find files which client should not include in generation of md5sum
	#deleted removed files loaded from previous packages
	var result = {
		"update" : [],
		"remove" : [],
		"add"    : []
	}
	var compare = []
	for name in src_list:
		if not dest_list.has(name):
			result["remove"].append(name)
	for name in dest_list:
		if not src_list.has(name):
			result["add"].append(name)
		else:
			compare.append(name)
	for name in compare:
		if src_list[name] != dest_list[name]:
			result["update"].append(name)
	return result

var upt_info_cache = {}
var upt_info_cache_max = 100
func upt_info_cache_put(info, md5id):
	upt_info_cache[md5id] = info
	if upt_info_cache.size() > upt_info_cache_max:
		var i = randi() % upt_info_cache.size()
		var k = upt_info_cache.keys()[i]
		upt_info_cache.erase(k)
	#check if it has all the keys
	if not info.has_all(["add", "remove", "update", "size"]):
		Log("Update info, not all keys present, in %s" % md5id)

func upt_save_update_info(cid, sid, stat):
	#part of thread do not use graphical logging here, coredumps with seg 11, in 3.1
	printd("Save update stats for client %s server %s" % [cid, sid])
	var savefile = File.new()
	savefile.open(upt_name(cid, "stat"), File.WRITE)
	savefile.store_line(var2str(stat))
	savefile.close()
	upt_info_cache_put(stat, cid)

func upt_info(md5id):
	var info
	if upt_info_cache.has(md5id):
		info = upt_info_cache[md5id]
		return info
	
	var iname = upt_name(md5id, "stat")
	if file.file_exists(iname):
		printd("Load update stats for client %s" % md5id)
		var ifile = File.new()
		ifile.open(iname, File.READ)
		info = str2var(ifile.get_as_text())
		ifile.close()
		upt_info_cache_put(info, md5id)

func upt_create(opt):
	#part of thread do not use graphical logging here, coredumps with seg 11, in 3.1
	var client_id = opt[0]
	var server_id = opt[1]
	var client_list = opt[2]

	var updated_files
	var compare = upt_compare_lists(client_list, tree_md5_list)
	
	printd("client update/add/remove %s %s/%s/%s" % [client_id, compare["update"].size(), compare["add"].size(), compare["remove"].size()])
	
	updated_files = compare["add"] + compare["update"]
	
# 	print(updated_files)
	
	if updated_files.empty():
		printd("No new files found!")
		compare["size"] = 0
	else:
		printd("Found files to update %s" % updated_files.size())
	
		var packer = PCKPacker.new()
		var package_path = upt_name(client_id)
		
		printd("make update: %s" % package_path)
		
		packer.pck_start(package_path, 4)
		
		for fname in updated_files:
			packer.add_file(fname, fname)
		
		packer.flush(true)
		printd("make update done: %s" % package_path)
		file.open(package_path, File.READ)
		compare["size"] = file.get_len()
		file.close()

	upt_save_update_info(client_id, server_id, compare)
	emit_signal("update_ready", client_id)

func ServerUpdateProtocol(var client_id, var version):
	if version != protocol_version:
		Log("mismatch update protocol version")
		toClient(client_id, "client_protocol_mismatch")
	else:
		toClient(client_id, "client_protocol_ok")

func ServerReceiveMD5id(var client_id, var md5id):
	Log("Recieve client tree id : %s, current id is %s" % [md5id, tree_md5id])
	if md5id == tree_md5id:
		toClient(client_id, "current")
		return
	if upt_exists(md5id):
		Log("Update for client exist, ready to send")
		var info = upt_info(md5id)
		if info == null:
			Log("Error getting update info, abort update process for %s" % md5id)
			toClient(client_id, "abort")
		else:
			toClient(client_id, "update_info", info)
	else:
		if thread.is_active():
			toClient(client_id, "wait")
			Log("already making update package, send wait to client")
		else:
			toClient(client_id, "list")

func ServerReceiveMD5List(var client_id, var md5_list, var md5_id):
	if thread.is_active():
		Log("Recieving list while packing thread is active, should have not happened, restart update")
		toClient(client_id, "restart")
		return
		
	Log("Server received md5 list.")
	Log("Client list contains %s entries" % md5_list.size())
	Log("Server list contains %s entries" % tree_md5_list.size())
	
	toClient(client_id, "wait")
	Log("Start making update, thread")
	thread.start(self, "upt_create", [md5_id, tree_md5id, md5_list])

func ServerSendUpdate(var client_id, var md5_id):
	if not upt_exists(md5_id):
		#some mistake happened
		Log("Client requesting nonexisting update, %s" % md5_id)
		toClient(client_id, "abort")
		return
	if not client_ids.has(client_id):
		Log("ServerSendUpdate error, client id does not exists %s" % client_id)
		return
	var file
	var client_status
	if client_ids[client_id].has("download_status"):
		client_status = client_ids[client_id].download_status
		file = client_status.fh
	else:
		var package_path = upt_name(md5_id)
		file = File.new()
		file.open(package_path, File.READ)
		client_status = {
			"fh" : file,
			"fhn" : package_path,
			"pos" : 0,
			"target" : file.get_len()
		}
		client_ids[client_id]["download_status"] = client_status
	
	var buffer_size = UPDATE_CHUNK_SIZE
	if buffer_size > client_status.target - client_status.pos:
		buffer_size = client_status.target - client_status.pos
	var buffer = file.get_buffer(buffer_size)
	Log("Send update chunk to client, %s bytes of %s/%s to %s" % [buffer.size(), client_status.pos, client_status.target, client_id])
	toClient(client_id, "recv_data", buffer)
	client_status.pos += buffer.size()
	
	if client_status.pos == client_status.target:
		Log("Update sent, %s/%s" % [client_status.pos, client_status.target])
		file.close()
		client_ids[client_id].erase("download_status")

func GetMD5id(dict):
	var join = ""
	var k = dict.keys()
	k.sort()
	printd("get md5id, dict size %s" % k.size())
	
	for s in k:
		join += s + dict[s]
	return join.md5_text()

func UpdateTreeID():
	tree_md5_list = GetMD5List()
	tree_md5id = GetMD5id(tree_md5_list)
	Log("Tree id is: %s" % tree_md5id)

func upt_ClientUpdateName():
	#This will name the package by number. i.e. 00005.pck
	var package_name
	var nr_packages = 0
	if directory.open(user_updates_path) == OK:
		directory.list_dir_begin(true, true)
		var file_name = directory.get_next()
		while (file_name != ""):
			if not directory.current_is_dir():
				nr_packages += 1
			file_name = directory.get_next()
		directory.list_dir_end()
		package_name = str(nr_packages).pad_zeros(5)
		package_name = "%s%s%s" % [user_updates_path, package_name, ".pck"]
	else:
		Log("Could not write to user directory.")
	return package_name

func ClientReceiveUpdate(var buffer):
	if not update_status.has("target_size"):
		ClientUpdateEnd(false)
		Log("Error, no data to download, should not be there")
		return
	var size = buffer.size()
	var tsize = update_status["target_size"]
	if not update_status.has("fh") or update_status["fh"] == null:
		var package_name = upt_ClientUpdateName()
		Log("Init update file %s " % package_name)
		if package_name == null:
			Log("Fail to create file for storing the update")
			ClientUpdateEnd(false)
			return
		var file = File.new()
		file.open(package_name, File.WRITE)
		update_status["fh"] = file
		update_status["fhn"] = package_name

	var file = update_status["fh"]
	file.store_buffer(buffer)
	update_status["current_size"] += size
	Log("ClientReceiveUpdate, chunk %s bytes %s/%s" % [size, update_status["current_size"], tsize])
	emit_signal("update_progress", round(update_status["current_size"]/tsize) * 100)

	if update_status["current_size"] == update_status["target_size"]:
		file.close()
		Log("Done writing new update package.")
		LoadPackageFile(update_status["fhn"])
		UpdateTreeID()
		Log("current tree id %s" % tree_md5id)
		ClientUpdateEnd(true)
	if update_status["current_size"] > update_status["target_size"]:
		var sname = update_status["fhn"]
		var dname = "%s_" % sname
		var result = directory.rename(sname, dname)
		Log("Error update dowloading file, move file to %s, result %s" % [dname, result])
		ClientUpdateEnd(false)
	if update_status["current_size"] < update_status["target_size"]:
		toServer("send_data", tree_md5id)

func GetMD5List():
	var dictionary = {}
	var path = "res://"
	GetMD5FromDirectory(path, dictionary)
	Log("GetMD5List total list of files %s" % dictionary.size())
	return dictionary

func FilterMD5(path):
	#check path to be filtered, return true if include, false if exclude
	var result = true
	if path == null:
		return result
	for p in filter["include"]:
		if path.match(p):
			result = true
			break
	for p in filter["exclude"]:
		if path.match(p):
			result = false
			break
	for p in filter["ignore"]:
		if path == p:
			result = false
	return result


func GetMD5FromDirectory(var path, var dictionary):
# #debug
	if upt_debug and dictionary.size() > 50:
		return

	var directory = Directory.new()
	if directory.open(path) == OK:
		Log("GetMD5FromDirectory open %s, cwd(%s)" % [path, directory.get_current_dir()])
		directory.list_dir_begin(true, true)
		
		var file_name = directory.get_next()
		while (file_name != ""):
			file_name = path + file_name
			if FilterMD5(file_name):
				if directory.current_is_dir():
					file_name += "/"
					Log("GetMD5FromDirectory dive in: %s" % file_name)
					GetMD5FromDirectory(file_name, dictionary)
				else:
					var file_md5 = "%s" % file.get_md5(file_name)
					dictionary[file_name] = file_md5
					Log("%s md5=%s" % [file_name, file_md5])
			else:
				Log("skip %s" % file_name)
			file_name = directory.get_next()
	else:
		Log("GetMD5FromDirectory fail to open %s" % path)

func LoadPackageFile(fname):
# 	var prjcfg = "res://project.cfg"
# 	printd("LoadPackageFile, application/run/main_scene %s" % ProjectSettings.get_setting("application/run/main_scene"))
	var success = ProjectSettings.load_resource_pack(fname)
	Log("Loading File: " + fname + " success" if success else " unsuccessful")
# 	if file.file_exists(prjcfg):
# 		printd("LoadPackageFile, config file %s present, override" % prjcfg )
# 		ProjectSettings.set_setting("application/config/project_settings_override", prjcfg)

	printd("LoadPackageFile, application/run/main_scene %s" % ProjectSettings.get_setting("application/run/main_scene"))
	return success

func LoadPackages(path=null, first=false):
	if path == null:
		path = user_updates_path
	var directory = Directory.new()
	var package_list = []
	if directory.open(path) == OK:
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
					var fname = directory.get_current_dir() + file_name
					package_list.append(fname)
			file_name = directory.get_next()
	else:
		print("An error occurred when trying to access the path.")
	package_list.sort()
	if first and package_list.size() > 0:
		var fname = package_list.pop_back()
		LoadPackageFile(fname)
	else:
		for fname in package_list:
			LoadPackageFile(fname)


func thread_active_correction(client_id):
	printd("packing finished for %s" % client_id)
	#thread::is_active does not deactivate on its own without waiting for finish, probably a bug/feature
	thread.wait_to_finish()
# 	printd("finish wait for thread %s, thread status active(%s)" % [client_id, thread.is_active()])

func Log(var text):
	if logg.test_fd(debug_id, text) > 0:
		emit_signal("receive_update_message", text)
	printd(text)

var debug_id = "Updater"
func printd(s):
	logg.print_fd(debug_id, s)
