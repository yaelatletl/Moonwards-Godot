extends Node
#world scene to load

#var world = preload("res://World.tscn")

# Default game port
const DEFAULT_PORT = 10567

# Max number of players
const MAX_PEERS = 12

# Name for my player
var player_name = "The Warrior"

# Names for remote players in id:name format
var players = {}
var player_data = {
	name = "Anonmous, The Warrior"
} setget player_data_set, player_data_get

var player_local
var network_id

#
# hold last error message
var error_msg = "Ok"
# indicate server role, mutial to client role
var RoleServer = false
#indicate client role, mutual to server role
var RoleClient = false

#global signals
signal gslog(msg)
# network user related
signal user_join #emit when user is fully registered
signal user_leave #emit on leave of registered user
signal user_msg(id, msg) #emit message of id user
signal player_id(id)
#network server
signal server_up
#network client
signal server_connected
#network general
signal server_select # show dialog to connect to a server or create a server
signal network_error(message)
signal network_log(message) #emmit on change in server status, client status - conenction, establishing connection etc

#scenes
signal scene_change
signal scene_change_name(name)
signal scene_change_error(msg)
signal player_scene #emit when a scene for players is detected

# Signals to let lobby GUI know what's going on
signal player_list_changed
signal connection_failed
signal connection_succeeded
signal game_ended
signal game_error(what)

#################
# utils

func bindsig(_signal, _sub, obj, obj2, d = 0):
	if _sub == null:
		_sub = "sg_%s" % _signal
	if d == 0:
		if obj.is_connected(_signal, obj2, _sub):
			obj.disconnect(_signal, obj2, _sub)
			emit_signal("gslog", "disconnect signal %s, from %s to %s::%s" % [_signal, obj, obj2, _sub])
		else:
			obj.connect(_signal, obj2, _sub)
			emit_signal("gslog", "connect signal %s, from %s to %s::%s" % [_signal, obj, obj2, _sub])
	elif d == 1 : #connect
		if not obj.is_connected(_signal, obj2, _sub):
			obj.connect(_signal, obj2, _sub)
	elif d == 2 : #disconnect
		if obj.is_connected(_signal, obj2, _sub):
			obj.disconnect(_signal, obj2, _sub)

func bindtg(_signal, _sub = null):
	#connect or disconnect tree to gamestate
	var obj = get_tree()
	var obj2 = self
	bindsig(_signal, _sub, obj, obj2, 0)

func bindtgc(_signal, _sub = null):
	#connect tree to gamestate
	var obj = get_tree()
	var obj2 = self
	bindsig(_signal, _sub, obj, obj2, 1)

func bindtgd(_signal, _sub = null):
	#disconnect tree from gamestate
	var obj = get_tree()
	var obj2 = self
	bindsig(_signal, _sub, obj, obj2, 2)

func bindgg(_signal, _sub = null):
	#bind gamestate to gamestate
	var obj = self
	var obj2 = self
	bindsig(_signal, _sub, obj, obj2, 0)

#################
#Track scene changes and add nodes or emit signals

var _queue_attach = {}
func queue_attach(path, node, permanent = false):
	emit_signal("gslog", "attach queue(permanent %s): %s(%s)" % [permanent, path, node])
	var packedscene
	if node.get_class() == "String":
		packedscene = ResourceLoader.load(node)
		emit_signal("gslog", "loading resource in queue_attach(%s, %s, %s)" % [path, node, permanent])
		if not packedscene:
			emit_signal("gslog", "error loading resource in queue_attach(%s, %s, %s)" % [path, node, permanent])
			return
	if not packedscene:
		packedscene = node
	_queue_attach[path] = {
			path = path,
			permanent = permanent,
			node = node,
			packedscene = packedscene
		}
	print("+++", _queue_attach[path].packedscene)
	if not get_tree().is_connected("tree_changed", self, "queue_attach_on_tree_change") :
		get_tree().connect("tree_changed", self, "queue_attach_on_tree_change")

func queue_tree_signal(path, sig, permanent = false):
	emit_signal("gslog", "signal queue(permanent %s): %s(%s)" % [permanent, path, sig])
	_queue_attach[path] = {
			path = path,
			permanent = permanent,
			signal = sig,
		}
	if not get_tree().is_connected("tree_changed", self, "queue_attach_on_tree_change") :
		get_tree().connect("tree_changed", self, "queue_attach_on_tree_change")
	

var _queue_attach_on_tree_change_lock = false #emits tree_change events on adding node, prevent stack overflow
var _queue_attach_on_tree_change_prev_scene
func queue_attach_on_tree_change():
	if _queue_attach_on_tree_change_lock:
		return
	if get_tree():
		if _queue_attach_on_tree_change_prev_scene != str(get_tree().current_scene):
			_queue_attach_on_tree_change_prev_scene = str(get_tree().current_scene)
			emit_signal("gslog", "qatc: Scene changed %s" % _queue_attach_on_tree_change_prev_scene)
			for p in _queue_attach:
				if _queue_attach[p].has("node"):
					emit_signal("gslog", "qatc: node %s(%s) permanent %s" % [p, _queue_attach[p].node, _queue_attach[p].permanent])
				if _queue_attach[p].has("signal"):
					emit_signal("gslog", "qatc: signal %s(%s) permanent %s" % [p, _queue_attach[p].signal, _queue_attach[p].permanent])
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
							emit_signal("gslog", "qatc, emit and remove: %s(%s) permanent %s" % [p, _queue_attach[p].signal, _queue_attach[p].permanent])
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
						emit_signal("gslog", "qatc, attached and removed: %s(%s) permanent %s" % [p, _queue_attach[p].node, _queue_attach[p].permanent])
						_queue_attach.erase(p)
						scene.print_tree_pretty()
					else:
						_queue_attach[p]["scene"] = scene


#################
# signal logging

func sg_network_log(msg):
	print("Server log: %s" % msg)

func sg_gslog(msg):
	print("gamestate log: %s" % msg)

func on_scene_change_log():
	print("===gs on_scene_change")
	print("get_tree: ", get_tree())
	if get_tree():
		if get_tree().current_scene :
			print("current scene: ", get_tree().current_scene)


#################
#Server functions
var server = {
	host = "localhost",
	ip = "127.0.0.1",
	connection = null,
	up = false
}

func server_set_mode(host="localhost"):
	if RoleClient :
		emit_signal("network_error", "Currently in client mode")
		return
	if RoleServer :
		emit_signal("network_error", "Already in server mode")
		return
	RoleServer = true
	
	server.host = host
	server.ip = IP.resolve_hostname(host, 1) #TYPE_IPV4 - ipv4 adresses only
	if not server.ip.is_valid_ip_address():
		var msg = "fail to resolve host(%s) to ip adress" % server.host
		emit_signal("network_log", msg)
		emit_signal("network_error", msg)
		RoleServer = false
		return
	emit_signal("network_log", "prepare to listen on %s:%s" % [server.ip,DEFAULT_PORT])
	server.connection = NetworkedMultiplayerENet.new()
	server.connection.set_bind_ip(server.ip)
	var error = server.connection.create_server(DEFAULT_PORT, MAX_PEERS)
	if error == 0:
		get_tree().set_network_peer(server.connection)
		emit_signal("network_log", "server up on %s:%s" % [server.ip,DEFAULT_PORT])
		server.up = true
		bindtgc("tree_changed", "server_tree_changed")
		emit_signal("server_up")
		server.connection.connect("peer_connected", self, "server_user_connected")
		server.connection.connect("peer_disconnected", self, "server_user_disconnected")
# 		emit_signal("connection_succeeded")
		get_tree().connect("network_peer_connected", self, "server_tree_user_connected")
		get_tree().connect("network_peer_disconnected", self, "server_tree_user_disconnected")

		emit_signal("gslog", "network server id %s" % server.connection.get_unique_id())
		network_id = server.connection.get_unique_id()
		emit_signal("player_id", network_id)
	else:
		emit_signal("network_log", "server error %s" % error)
		emit_signal("network_error", "failed to bring server up, error %s" % error)
		RoleServer = false
# 		emit_signal("connection_failed")

func server_tree_changed():
	if not RoleServer or not server.up:
		return
	var root = get_tree()
	if root != null and root.get_network_unique_id() == 0:
		root.set_network_peer(server.connection)
		emit_signal("network_log", "reconnect server to tree")

func server_user_connected(id):
	emit_signal("gslog", "user connected %s" % id)

func server_user_disconnected(id):
	emit_signal("gslog", "user disconnected %s" % id)

func server_tree_user_connected(id):
	emit_signal("gslog", "tree user connected %s" % id)

func server_tree_user_disconnected(id):
	emit_signal("gslog", "tree user disconnected %s" % id)

################
#Client functions
var client = {
	host = "localhost",
	ip = "127.0.0.1",
	port = DEFAULT_PORT,
	connection = null,
	up = false
}

func sg_connection_failed():
	emit_signal("gslog", "client connection failed to %s(%s):%s" % [player_get("host"), player_get("ip"), player_get("port")])
	bindtgd("connection_failed")
	bindtgd("connected_to_server")
	RoleClient = false
	emit_signal("network_error", "Error connecting to server %s(%s):%s" % [player_get("host"), player_get("ip"), player_get("port")])

func sg_connected_to_server():
	emit_signal("gslog", "client connected to %s(%s):%s" % [player_get("host"), player_get("ip"), player_get("port")])
	bindtgd("connection_failed")
	bindtgd("connected_to_server")
	RoleClient = true
	emit_signal("server_connected")

func client_server_connect(host, port=DEFAULT_PORT):
	if RoleClient :
		emit_signal("network_error", "Already in client mode")
		return
	if RoleServer :
		emit_signal("network_error", "Currently in server mode")
		return
	RoleClient = true
	
	client.host = host
	client.ip = IP.resolve_hostname(host, 1) #TYPE_IPV4 - ipv4 adresses only
	if not client.ip.is_valid_ip_address():
		var msg = "fail to resolve host(%s) to ip adress" % server.host
		emit_signal("network_log", msg)
		emit_signal("network_error", msg)
		RoleClient = false
		return
	client.port = port
	emit_signal("network_log", "connect to server %s(%s):%s" % [player_get("host"), player_get("ip"), player_get("port")])
	
	bindtgc("connection_failed")
	bindtgc("connected_to_server")
	client.connection = NetworkedMultiplayerENet.new()
	client.connection.create_client(player_get("ip"), player_get("port"))
	emit_signal("gslog", "network id %s" % client.connection.get_unique_id())
	network_id = client.connection.get_unique_id()
	emit_signal("player_id", network_id)
	get_tree().set_network_peer(client.connection)
	

################
# Scene functions
func change_scene(scene):
	var scenes = options.scenes
	if not scene in scenes:
		emit_signal("scene_change_error", "No such scence %s" % scene)
		emit_signal("gslog", "No such scence %s" % scene)
		return
	
	emit_signal("gslog", "change_scene to %s" % scene)
	var error = get_tree().change_scene(scenes[scene].path)
	if error == 0 :
		emit_signal("gslog", "changing scene okay(%s)" % error)
		scenes.loaded = scene
		emit_signal("scene_change")
		emit_signal("scene_change_name", scene)
	else:
		emit_signal("gslog", "error changing scene %s" % error)

func sg_player_scene():
	emit_signal("gslog", "scene is player ready, checking players")
	for p in players:
		emit_signal("gslog", "player %s" % players[p])
		create_player(p)

func is_player_scene():
	var result = false
	if get_tree() and get_tree().current_scene:
		if get_tree().current_scene.get_node(options.scene_id):
			result = true
	return result

################
# Player functions
func player_register(pdata, localplayer=false):
	if not pdata.has("id") and not localplayer:
		emit_signal("gslog", "player data should have id")
		return
	emit_signal("gslog", "register player(local %s): %s" % [localplayer, pdata])
	var player = {}
	player["data"] = pdata
	player["obj"] = options.player_scene.instance()
	player["camera"] = localplayer
	if localplayer:
		player_local = player
		#Switch camera off
		player.obj.get_node("Pivot").visible = true
		if network_id :
			player["id"] = network_id
			players[player.id] = player
	else:
		player.obj.get_node("Pivot").visible = false
		player["id"] = pdata.id
		players[player.id] = player
	
	if is_player_scene() and player.has("id"):
		create_player(player.id)

func sg_player_id(id):
	emit_signal("gslog", "player id(%s), player_local(%s)" % [id, player_local])
	if player_local:
		if not player_local.has("id"):
			player_local["id"] = id
			players[id] = player_local
			if is_player_scene():
				create_player(id)


func player_data_set(player):
	if not player.has("name"):
		emit_signal("gslog", "setting player data, error, no name")

func player_data_get():
	if not player_data.has("name"):
		emit_signal("gslog", "player data, error, no name")
	return player_data

func player_get(prop):
	var error = false
	var result = null
	if player_local.data.has(prop):
		result = player_local.data[prop]
	elif player_local.has(prop):
		result = player_local[prop]
	elif client.has(prop):
		result = client[prop]
	else:
		match prop:
			_:
				error = true
	if error:
		emit_signal("gslog", "error: player data, no property(%s)" % prop)
	return result

func create_player(id):
	var world = get_tree().current_scene
	if players[id].has("world") and players[id]["world"] == str(world):
		emit_signal("gslog", "player(%s) already added, %s" % [id, players[id]])
		return
	var spawn_pcount =  world.get_node("spawn_points").get_child_count()
	var spawn_pos = world.get_node("spawn_points").get_child(randi()%spawn_pcount).translation
	var player = players[id].obj
	player.flies = true # MUST CHANGE WHEN COLLISIONS ARE DONE
	player.set_name(str(id)) # Use unique ID as node name
	player.translation=spawn_pos
	player.set_network_master(id) #set unique id as master
	player.set_player_name(players[id].data.name)
	player.get_node("Pivot/FPSCamera").make_current()
	world.get_node("players").add_child(player)
	players[id]["world"] = "%s" % world
	players[id]["path"] = world.get_path_to(player)


# Callback from SceneTree
func _player_connected(id):
	emit_signal("gslog", "player connected id(%s)" % id)
	rpc("register_player", get_tree().get_network_unique_id(), player_get("name"))

sync func delete_player(id):
	
	var path = str("root/world/players/"+str(id))
	
	if (has_node(path)):
			get_node(path).queue_free()

# Callback from SceneTree
func _player_disconnected(id):
	if (get_tree().is_network_server()):
		if (has_node("/root/world")): # Game is in progress
			emit_signal("game_error", "Player " + players[id] + " disconnected")
			#end_game() Do not end the game
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			for p_id in players: #Delete the player for all players
				rpc_id(p_id, "delete_player", id)
			delete_player(id) #Delete the player for server
		else: # Game is not in progress
			# If we are the server, send to the new dude all the already registered players
			unregister_player(id)
			for p_id in players:
				# Erase in the server
				rpc_id(p_id, "unregister_player", id)

# Callback from SceneTree, only for clients (not server)
func _connected_ok():
	# Registration of a client beings here, tell everyone that we are here
	#ClientSide
	#get_tree().get_root().add_child(world)
	rpc("register_player", get_tree().get_network_unique_id(), player_name, true)
	rpc("create_player", get_tree().get_network_unique_id())
	
	emit_signal("connection_succeeded")

# Callback from SceneTree, only for clients (not server)
func _server_disconnected():
	emit_signal("game_error", "Server disconnected")
	end_game()

# Callback from SceneTree, only for clients (not server)
func _connected_fail():
	get_tree().set_network_peer(null) # Remove peer
	emit_signal("connection_failed")

# Lobby management functions

remote func register_player(id, new_player_name):
	emit_signal("gslog", "register_player id(%s) name(%s)" % [id, new_player_name])
	if get_tree().is_network_server():
		# If we are the server, let everyone know about the new player
		rpc_id(id, "register_player", 1, player_get("name")) # Send myself to new dude
		for p_id in players: # Then, for each remote player
			rpc_id(id, "register_player", p_id, players[p_id]) # Send player to new dude
			rpc_id(p_id, "register_player", id, new_player_name) # Send new dude to player

	var player = {
		name = new_player_name,
		id = id
	}
	player_register(player)
	emit_signal("player_list_changed")

remote func unregister_player(id):
	emit_signal("gslog", "unregister_player")
	return
	players.erase(id)
	emit_signal("player_list_changed")

remote func pre_start_game(spawn_points):
	emit_signal("gslog", "pre_start_game")
	return
	# Change scene
	var  WorldScene = options.scenes[options.scenes.default]
	var world = load(WorldScene).instance()
	world.name = "world"
	get_tree().get_root().add_child(world)

	get_tree().get_root().get_node("lobby").visible = false
	get_tree().get_root().get_node("Spatial/ui").hide()

	

	for p_id in spawn_points:
		create_player(p_id)
	if (not get_tree().is_network_server()):
		# Tell server we are ready to start
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif players.size() == 0:
		post_start_game()

remote func post_start_game():
	emit_signal("gslog", "post_start_game")
	return
	get_tree().set_pause(false) # Unpause and unleash the game!

var players_ready = []

remote func ready_to_start(id):
	emit_signal("gslog", "ready_to_start")
	return
	assert(get_tree().is_network_server())

	if (not id in players_ready):
		players_ready.append(id)

	if (players_ready.size() == players.size()):
		for p in players:
			rpc_id(p, "post_start_game")
		post_start_game()

func host_game(new_player_name):
	player_name = new_player_name
	var host = NetworkedMultiplayerENet.new()
	host.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(host)

func join_game(ip, new_player_name):
	player_name = new_player_name
	var host = NetworkedMultiplayerENet.new()
	host.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(host)

func get_player_list():
	return players.values()

func get_player_name():
	return player_name

func begin_game():
	assert(get_tree().is_network_server())

	# Create a dictionary with peer id and respective spawn points, could be improved by randomizing
	var spawn_points = {}
	spawn_points[1] = 0 # Server in spawn point 0
	var spawn_point_idx = 1
	for p in players:
		spawn_points[p] = spawn_point_idx
		spawn_point_idx += 1
	# Call to pre-start game with the spawn points
	for p in players:
		rpc_id(p, "pre_start_game", spawn_points)

	pre_start_game(spawn_points)

func end_game():
	if (has_node("/root/world")): # Game is in progress
		# End it
		get_node("/root/world").queue_free()

	emit_signal("game_ended")
	players.clear()
	get_tree().set_network_peer(null) # End networking

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	#get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	##get_tree().connect("connected_to_server", self, "_connected_ok")
	#get_tree().connect("connection_failed", self, "_connected_fail")
	#get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	bindgg("network_log")
	bindgg("gslog")
	#bindgg("scene_change", "player_toscene")
# 	get_tree().connect("tree_changed", self, "on_scene_change_log")
	#queue_attach("players", player_scene, true)
	bindgg("player_scene")
	bindgg("player_id")
	queue_tree_signal(options.scene_id, "player_scene", true)
