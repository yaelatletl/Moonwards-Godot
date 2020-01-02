extends Node
enum MODE {
	DISCONNECTED = 0,
	CLIENT = 1,
	SERVER = 2,
	ERROR = -1
	}
#global signals
# network user related
# warning-ignore:return_value_discarded

signal user_name_disconnected(name) #emit when user is joined, for chat
signal user_name_connected(name) #emit when user is disconnected, for chat

signal player_id(id) #emit id of player after establishing a connection
signal player_scene
#network server
signal server_up
#network client
signal server_connected
#network general
signal client_connected


#scenes
signal scene_change
signal scene_change_name(name)
signal scene_change_error(msg)

signal loading_done
signal loading_error(msg)


# Signals to let lobby GUI know what's going on
signal connection_failed

signal game_ended
signal game_error(what)

# Default game port
const DEFAULT_PORT : int = 10567

# Max number of players
const MAX_PEERS : int = 12

# remote players in id:player_data format
var players : Dictionary = {}
var network_id : int 
var local_id : int = 0

#
# hold last error message



var _queue_attach : Dictionary = {}
var _queue_attach_on_tree_change_lock : bool = false #emits tree_change events on adding node, prevent stack overflow
var _queue_attach_on_tree_change_prev_scene : String

var host : String = "localhost"
var ip : String = "127.0.0.1"
var connection = null
var port : int = DEFAULT_PORT


var NetworkState : int = MODE.DISCONNECTED # 0 disconnected. 1 Connected as client. 2 Connected as server -1 Error



var PlayerSceneUP : bool = false
#signal player(node_path) #emit when local player instanced to scene
#################
# util functions

var level_loader : Object = preload("res://scripts/LevelLoader.gd").new()
var world : Node = null


func _ready():
	
	local_id = 0
	NodeUtilities.bind_signal("player_scene", "", self, self, NodeUtilities.MODE.TOGGLE)
	NodeUtilities.bind_signal("player_id", "", self, self, NodeUtilities.MODE.TOGGLE)
	
	queue_tree_signal(Options.scene_id, "player_scene", true)
	

	_net_tree_connect_signals()



#################
#Track scene changes and add nodes or emit signals functions


func queue_attach(path : String, node, permanent : bool = false) -> void: #node is variant
	Log.hint(self, "queue_attach", str("attach queue(permanent: ", str(permanent),"): ", path, "(", node, ")")) 
	var packedscene
	if node is String:
		packedscene = ResourceLoader.load(node)
		Log.hint(self, "queue_attach", str("loading resource in queue_attach(", path, ", ", node, ", ", permanent,")"))
		if not packedscene:
			Log.error(self, "queue_attach", str("error loading resource in queue_attach(", path, ", ", node, ", ", permanent,")"))
			return
	if not packedscene:
		packedscene = node
	_queue_attach[path] = {
			path = path,
			permanent = permanent,
			node = node,
			packedscene = packedscene
		}
	Log.hint(self, "queue_attach", str("+++", _queue_attach[path].packedscene))
	NodeUtilities.bind_signal("tree_changed","_on_queue_attach_on_tree_change", get_tree(), self, NodeUtilities.MODE.CONNECT) 

func queue_tree_signal(path : String, signal_name : String, permanent : bool = false) -> void:
	Log.hint(self, "queue_tree_signal", "signal queue(permanent %s): %s(%s)" % [permanent, path, signal_name])
	_queue_attach[path] = {
			path = path,
			permanent = permanent,
			signal = signal_name,
		}
	NodeUtilities.bind_signal("tree_changed", "_on_queue_attach_on_tree_change", get_tree(), self, NodeUtilities.MODE.CONNECT)


#################
# general network functions

func _net_tree_connect_signals(connect : bool = true) -> void:
	var tree = get_tree()
	
	var signals = [
		["connected_to_server", "_on_net_server_connected", tree],
		["server_disconnected", "_on_net_server_disconnected", tree],
		["connection_failed", "_on_net_connection_fail", tree],
		["network_peer_connected", "", tree],
		["network_peer_disconnected", "", tree],
		["server_up", "_on_net_server_up", self]
	]
	for sg in signals:
		Log.hint(self, "queue_attach", str("net_tree_connect", sg[0], " -> " , sg[1]))
		if connect:
			NodeUtilities.bind_signal(sg[0], sg[1], sg[2], self, NodeUtilities.MODE.CONNECT)
		else:
			NodeUtilities.bind_signal(sg[0], sg[1], sg[2], self, NodeUtilities.MODE.DISCONNECT)



#################
#Server functions


func server_set_mode(host : String = "localhost"):
	match NetworkState:
		MODE.CLIENT:
			Log.error(self, "client_server_connect", "Currently in client mode")
			return
		MODE.SERVER:
			Log.error(self, "client_server_connect", "Already in server mode")
			return
		MODE.ERROR:
			Log.error(self, "client_server_connect", "No-network-mode enabled")
			return
		MODE.DISCONNECTED:
			continue
	
	NetworkState = MODE.SERVER
	
	self.host = host
	ip = IP.resolve_hostname(host, 1) #TYPE_IPV4 - ipv4 adresses only
	if not ip.is_valid_ip_address():
		Log.hint(self, "server_set_mode",  str("fail to resolve host(",host,") to ip adress"))
		NetworkState = MODE.DISCONNECTED
		return
	Log.hint(self, "server_set_mode", str("prepare to listen on ", ip, ":", DEFAULT_PORT))
	connection = NetworkedMultiplayerENet.new()
	connection.set_bind_ip(ip)
	var error : int = connection.create_server(DEFAULT_PORT, MAX_PEERS)
	if error == OK:
		get_tree().set_network_peer(connection)
		Log.hint(self, "server_set_mode", str("server up on ", ip, ":", DEFAULT_PORT))
		NetworkState = MODE.SERVER
		NodeUtilities.bind_signal("tree_changed", "_on_server_tree_changed", get_tree(), self, NodeUtilities.MODE.CONNECT)
		emit_signal("server_up")
		
		NodeUtilities.bind_signal("peer_disconnected", "_on_server_user_disconnected", connection, self, NodeUtilities.MODE.CONNECT) 
		NodeUtilities.bind_signal("peer_connected", "_on_server_user_connected", connection, self, NodeUtilities.MODE.CONNECT) 
		
		NodeUtilities.bind_signal("network_peer_connected", "_on_server_tree_user_connected", get_tree(), self, NodeUtilities.MODE.CONNECT)
		NodeUtilities.bind_signal("network_peer_disconnected", "_on_server_tree_user_disconnected", get_tree(), self, NodeUtilities.MODE.CONNECT)
		
		network_id = connection.get_unique_id()
		Log.hint(self, "server_set_mode", str("network server id ", network_id))
		
		emit_signal("player_id", network_id)
	else:
		Log.hint(self, "server_set_mode", "server error %s" % Log.error_to_string(error))
		Log.hint(self, "server_set_mode", "failed to bring server up, error %s" % Log.error_to_string(error))
		NetworkState = MODE.DISCONNECTED

################
#Client functions




func client_server_connect(host : String, port : int = DEFAULT_PORT):
	match NetworkState:
		MODE.CLIENT:
			Log.error(self, "client_server_connect", "Already in client mode")
			return
		MODE.SERVER:
			Log.error(self, "client_server_connect", "Currently in server mode")
			return
		MODE.ERROR:
			Log.error(self, "client_server_connect", "No-network-mode enabled")
			return
		MODE.DISCONNECTED:
			continue
	
	NetworkState = MODE.CLIENT 
	
	host = host
	ip = IP.resolve_hostname(host, 1) #TYPE_IPV4 - ipv4 adresses only
	if not ip.is_valid_ip_address():
		var msg = str("fail to resolve host(", host, ") to ip adress")
		Log.error(self, "client_server_connect", msg)
		NetworkState = MODE.DISCONNECTED
		return
	self.port = port
	Log.hint(self, "client_server_connect", "connect to server %s(%s):%s" % [host, ip, port])
	
	NodeUtilities.bind_signal("connection_failed", '', get_tree(), self, NodeUtilities.MODE.CONNECT)
	NodeUtilities.bind_signal("connected_to_server", "", get_tree(), self, NodeUtilities.MODE.CONNECT)
	connection = NetworkedMultiplayerENet.new()
	connection.create_client(ip, port)
	Log.hint(self, "client_server_connect", str("network id ", connection.get_unique_id()))
	network_id = connection.get_unique_id()
	emit_signal("player_id", network_id)
	get_tree().set_network_peer(connection)


################
# Scene functions
func change_scene(scene : String) -> void:
	var scenes = Options.scenes
	if not scene in scenes:
		emit_signal("scene_change_error", "No such scene %s" % scene)
		Log.hint(self, "change_scene", "No such scene %s" % scene)
		return
	
	Log.hint(self, "change_scene", "change_scene to %s" % scene)
	var error = get_tree().change_scene(scenes[scene].path)
	if error == 0 :
		Log.hint(self, "change_scene", "changing scene okay(%s)" % Log.error_to_string(error))
		scenes.loaded = scene
		emit_signal("scene_change")
		emit_signal("scene_change_name", scene)
	else:
		Log.hint(self, "change_scene", "error changing scene %s" % Log.error_to_string(error))



func is_player_scene() -> bool:
	var result : bool = false
	if get_tree() and get_tree().current_scene:
		if get_tree().current_scene.has_node(Options.scene_id):
			result = true
	return result

################
# Player functions
func player_apply_opt(pdata : Dictionary, player : Spatial):
	#apply Options, given in register dictionary under ::Options
	if pdata.has("Options"):
		#printd("player_apply_opt to %s with %s" % [id, pdata])
		var opt = pdata.Options
		#printd("create_player Apply Options to id %s : %s" % [id, opt])
		for k in opt:
			player.set(k, opt[k])
		if opt.has("input_processing") and opt["input_processing"] == false:
			#printd("disable input for player avatar %s" % id)
			player.set_process_input(false)

func player_register(pdata : Dictionary, localplayer : bool = false, opt_id : String = "avatar") -> void:
	var id : int = 0
	if localplayer:
		pdata["Options"] = Options.player_opt(opt_id, pdata) #merge name with rest of Options for Avatar
		if network_id:
			id = network_id
		else:
			id = local_id
	elif pdata.has("id"):
		id = pdata.id
	else:
		Log.hint(self, "player_register", "player data should have id or be a local")
		return
	
	Log.hint(self, "player_register", "registered player(%s): %s" % [id, pdata])
	var player = {}
	player["data"] = pdata
	player["obj"] = Options.player_scene.instance()
	player_apply_opt(player["data"], player["obj"])
# 	player["localplayer"] = localplayer
	if localplayer:
		if network_id :
			player["id"] = id
		players[id] = player
	else:
		player["id"] = id
		players[id] = player
	
	if is_player_scene():
		create_player(id)

#local player recieved network id

remote func register_client(id : int, pdata : Dictionary) -> void:
	#printd("remote register_client, local_id(%s): %s %s" % [local_id, id, pdata])
	if id == local_id:
		#printd("Local player, skipp")
		return
	if players.has(id):
		#printd("register client(%s): already exists(%s)" % [local_id, id])
		return
	#printd("register_client: id(%s), data: %s" % [id, pdata])
	pdata["id"] = id
	if pdata.has("Options"):
		pdata["Options"] = Options.player_opt("puppet", pdata["Options"])
	else:
		pdata["Options"] = Options.player_opt("puppet")

	player_register(pdata)
	if NetworkState == MODE.SERVER:
		#sync existing players
		rpc("register_client", id, pdata)
		for p in players:
			#printd("**** %s" % players[p])
			var pid = players[p].id
			if pid != id:
				rpc_id(id, "register_client", pid, players[p].data)

remote func unregister_client(id : int) -> void:
	Log.hint(self, "unregister client", str("(",id,")"))
	if players.has(id):
		emit_signal("user_name_disconnected", "%s" % player_get("name", id))
		if players[id].obj:
			players[id].obj.queue_free()
# warning-ignore:return_value_discarded
		players.erase(id)
	if NetworkState == MODE.SERVER:
		#sync existing players
		for p in players:
			Log.hint(self, "unregister_client", "**** %s" % players[p])
			var pid = players[p].id
			if pid != local_id:
				rpc_id(pid, "unregister_client", id)


func player_get(prop, id : int = -1): #prop and result are variants
	if id == -1:
		id = local_id
	var error : bool = false
	var result = null
	if not players.has(id):
		return result
	if players[id].data.has(prop):
		result = players[id].data[prop]
	elif players[id].has(prop):
		result = players[id][prop]

	else:
		match prop:
			"name" :
				result = players[id].obj.username
			_:
				error = true
	if error:
		Log.error(self, "player_get", "error: player data, no property(%s)" % prop)
	return result

#remap local user for its network id, when he gets it
func player_remap_id(old_id : int, new_id : int) -> void:
	if players.has(old_id):
		var player = players[old_id]
# warning-ignore:return_value_discarded
		players.erase(old_id)
		players[new_id] = player
		player["id"] = new_id
		Log.hint(self, "player_remap", "remap player old_id(%s), new_id(%s)" % [old_id, new_id])
		if player.has("path"):
			var node = player.obj
			node.name = "%s" % new_id
			var world = get_tree().current_scene
			Log.hint(self, "player_remap", "remap player, old path %s to %s" % [player.path, world.get_path_to(node)])
			player["path"] = world.get_path_to(node)
			node.set_network_master(new_id)

func create_player(id : int) -> void:
	var world = get_tree().current_scene
	if players[id].has("world") and players[id]["world"] == str(world):
		Log.hint(self, "create_player", "player(%s) already added, %s" % [id, players[id]])
		return
	var spawn_pcount =  world.get_node("spawn_points").get_child_count()
	var spawn_pos = randi() % spawn_pcount
	Log.hint(self, "create_player", "select spawn point(%s/%s)" % [spawn_pos, spawn_pcount])
	spawn_pos = world.get_node("spawn_points").get_child(spawn_pos).translation
	var player = players[id].obj
#	player.flies = true # MUST CHANGE WHEN COLLISIONS ARE DONE
	player.set_name(str(id)) # Use unique ID as node name
	player.translation=spawn_pos
	
	if players[id].data.has("network"):
		player.nonetwork = !players[id].data.network
	
	Log.hint(self, "create_player", "cp set_network will set(%s) %s %s" % [players[id].has("id") and not player.nonetwork, players[id].has("id"), not player.nonetwork])
	if players[id].has("id") and not player.nonetwork:
		Log.hint(self, "create_player", "create player set_network_master player id(%s) network id(%s)" % [id, players[id].id])
		player.set_network_master(players[id].id) #set unique id as master
	
	Log.hint(self, "create_player", "==create player(%s) %s; name(%s)" % [id, players[id], players[id].data.username])
	world.get_node("players").add_child(player)
	players[id]["world"] = "%s" % world
	players[id]["path"] = world.get_path_to(player)
	emit_signal("user_name_connected", player_get("name", id))
	
	# HACK: Does not belong here
	# TODO: Once joining a server, loading the world, etc is done, hide mainmenu
	MainMenu.hide()
	PauseMenu.hide()
	Hud.show()

#set current camera to local player
func player_local_camera(activate : bool = true) -> void:
	if players.has(local_id):
		players[local_id].obj.nocamera = !activate

func player_noinput(enable : bool = false) -> void:
	if players.has(local_id):
		players[local_id].obj.input_processing = enable

# Callback from SceneTree, only for clients (not server)

# Lobby management functions

func end_game() -> void:
	if (has_node("/root/world")): # Game is in progress
		# End it
		get_node("/root/world").queue_free()

	emit_signal("game_ended")
	players.clear()
	get_tree().set_network_peer(null) # End networking







func loading_done(var error : int) -> void:
	if error == OK or error == ERR_FILE_EOF:
		Log.hint(self, "loading_done", "changing scene okay(%s)" % level_loader.error)
		emit_signal("loading_done")
	else:
		Log.hint(self, "loading_done", "error changing scene %s" % level_loader.error)
		Log.hint(self, "loading_done", "Error! " + Log.error_to_string(error))

func load_level(var resource) -> void: #Resource is variant
	# Check if the resource is valid before switching to loading screen.
	if resource is String:
		if Options.scenes.has(resource):
			resource = Options.scenes[resource].path
		if not ResourceLoader.exists(resource):
			emit_signal("loading_error", "File does not exist: " + resource)
			return
	elif resource is PackedScene:
		if not resource.can_instance():
			emit_signal("loading_error", "Can not instance resource.")
			return
	
	level_loader.start_loading(resource)
	yield(self, "loading_done")
	
	world = level_loader.new_scene.instance()
	get_tree().get_root().add_child(world)
	get_tree().current_scene = world
	emit_signal("scene_change")

#################
# avatar network/scene functions

#network and player scene state



func player_scene() -> void:
	#printd("------instance avatars with networking(%s) - players count %s" % [NetworkUP, players.size()])
	PlayerSceneUP = true


func _on_queue_attach_on_tree_change() -> void:
	if _queue_attach_on_tree_change_lock:
		return
	if get_tree():
		if _queue_attach_on_tree_change_prev_scene != str(get_tree().current_scene):
			_queue_attach_on_tree_change_prev_scene = str(get_tree().current_scene)
			Log.hint(self, "_on_queue_attach_on_tree_change", "qatc: Scene changed %s" % _queue_attach_on_tree_change_prev_scene)
			for p in _queue_attach:
				if _queue_attach[p].has("node"):
					Log.hint(self, "_on_queue_attach_on_tree_change", "qatc: node %s(%s) permanent %s" % [p, _queue_attach[p].node, _queue_attach[p].permanent])
				if _queue_attach[p].has("signal"):
					Log.hint(self, "_on_queue_attach_on_tree_change", "qatc: signal %s(%s) permanent %s" % [p, _queue_attach[p].signal, _queue_attach[p].permanent])
		else:
			return #if scene is the same skip notifications
		if get_tree().current_scene:
			var scene = get_tree().current_scene
			for p in _queue_attach:
				if _queue_attach[p].has("scene") and _queue_attach[p].scene == scene:
					continue
				var obj = scene.get_node(p)
				if obj:
					#if signal emit and continue
					if _queue_attach[p].has("signal"):
						var sig = _queue_attach[p].signal
						if not _queue_attach[p].permanent:
							Log.hint(self, "_on_queue_attach_on_tree_change","qatc, emit and remove: %s(%s) permanent %s" % [p, _queue_attach[p].signal, _queue_attach[p].permanent])
							_queue_attach.erase(p)
							emit_signal(sig)
						else:
							_queue_attach[p]["scene"] = scene
							emit_signal(sig)
						continue
					print("==qaotc== object at(%s) - %s" % [p, obj])
					var obj2 = _queue_attach[p].packedscene
					_queue_attach_on_tree_change_lock = true
					obj.add_child(obj2.instance())
					_queue_attach_on_tree_change_lock = false
					if not _queue_attach[p].permanent:
						Log.hint(self, "_on_queue_attach_on_tree_change", "qatc, attached and removed: %s(%s) permanent %s" % [p, _queue_attach[p].node, _queue_attach[p].permanent])
# warning-ignore:return_value_discarded
						_queue_attach.erase(p)
						scene.print_tree_pretty()
					else:
						_queue_attach[p]["scene"] = scene

func _on_net_connection_fail() -> void:
	Log.hint(self, "on_net_connection_fail", "connection failed")
	NetworkState = MODE.DISCONNECTED

func _on_network_peer_connected(id : int) -> void:
	Log.hint(self, "on_network_peer_connected", str("Player: ", id, " connected"))
	emit_signal("client_connected")


func _on_network_peer_disconnected(id : int) -> void:
	Log.hint(self, "on_network_peer_disconnected", str("Player: ", id, " disconnected"))


func _on_net_server_connected() -> void:
	Log.hint(self, "on_net_server_connected", "Server connected")
	if not NetworkState == MODE.SERVER:
		NetworkState = MODE.SERVER

func _on_net_server_disconnected() -> void:
	Log.hint(self, "on_net_server_disconnected", "Server disconnected")
	if NetworkState == MODE.SERVER:
		NetworkState = MODE.DISCONNECTED
		
func _on_net_server_up() -> void:
	Log.hint(self, "on_net_server_up", "Server up")
	if not NetworkState == MODE.SERVER:
		NetworkState = MODE.SERVER

func _on_server_tree_changed() -> void:
	if not NetworkState == MODE.SERVER:
		return
	var root = get_tree()
	if root != null and root.get_network_unique_id() == 0:
		root.set_network_peer(connection)
		Log.hint(self, "_on_server_tree_changed", "reconnect server to tree")

func _on_server_user_connected(id : int) -> void:
	Log.hint(self, "_on_server_user_connected", "user connected %s" % id)

func _on_server_user_disconnected(id : int) -> void:
	Log.hint(self, "_on_server_user_disconnected","user disconnected %s" % id)

func _on_server_tree_user_connected(id : int) -> void:
	Log.hint(self, "_on_server_tree_user_connected", "tree user connected %s" % id)

func _on_server_tree_user_disconnected(id : int) -> void:
	Log.hint(self, "_on_server_tree_user_disconnected", "tree user disconnected %s" % id)
	unregister_client(id)


func _on_player_scene() -> void:
	Log.hint(self, "_on_player_scene", "scene is player ready, checking players(%s)" % players.size())
	if Options.Debugger:
		for p in players:
			Log.hint(self, "_on_player_scene",  "player %s" % players[p])
	for p in players:
		create_player(p)
	
	if NetworkState == MODE.CLIENT:
		#report client to server
		rpc_id(1, "register_client", network_id, players[local_id].data)


func _on_player_id(id : int) -> void:
	if not players.has(local_id):
		return
	player_remap_id(local_id, id)
	local_id = id
	#scene is not active yet, payers are redistered after scene is changes sucessefully


func _server_disconnected() -> void:
	emit_signal("game_error", "Server disconnected")
	end_game()

# Callback from SceneTree, only for clients (not server)
func _connected_fail() -> void:
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")

func _on_connection_failed() -> void:
	Log.error(self, "_on_connection_failed", "client connection failed to %s(%s):%s" % [host, ip, port])
	NodeUtilities.bind_signal("connection_failed", '', get_tree(), self, NodeUtilities.MODE.DISCONNECT)
	NodeUtilities.bind_signal("connected_to_server", '', get_tree(), self, NodeUtilities.MODE.DISCONNECT)
	NetworkState = MODE.DISCONNECTED
	Log.error(self, "_on_connection_failed", "Error connecting to server %s(%s):%s" % [host, ip, port])

func _on_connected_to_server() -> void:
	Log.hint(self, "_on_connected_to_server",  "client connected to %s(%s):%s" % [host, ip, port])
	NodeUtilities.bind_signal("connection_failed", '', get_tree(), self, NodeUtilities.MODE.DISCONNECT)
	NodeUtilities.bind_signal("connected_to_server", '', get_tree(), self, NodeUtilities.MODE.DISCONNECT)
	NetworkState = MODE.CLIENT
	emit_signal("client_connected")



func _on_scene_change_log() -> void:
	Log.hint(self, "on_scene_change", "started change process")
	Log.hint(self, "on_scene_change", str("get_tree:", get_tree()))
	if get_tree():
		if get_tree().current_scene :
			Log.hint(self, "on_scene_change", str("current scene: ", get_tree().current_scene))
