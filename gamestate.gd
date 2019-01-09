extends Node
#world scene to load

var WorldScene = "res://World.tscn"
var player_scene = preload("res://assets/Player/player.tscn")

# Default game port
const DEFAULT_PORT = 10567

# Max number of players
const MAX_PEERS = 12

# Name for my player
var player_name = "The Warrior"

# Names for remote players in id:name format
var players = {}

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
signal user_join
signal user_leave
signal user_msg
#network server
signal server_up
#network client
signal server_connected
signal server_connecting
signal server_log(message) #emmit on change in server status - conenction, establishing connection etc
#network general
signal server_select # show dialog to connect to a server or create a server
signal network_error(message)

#scenes
signal scene_change
signal scene_change_name(name)
signal scene_change_error(msg)

# Signals to let lobby GUI know what's going on
signal player_list_changed
signal connection_failed
signal connection_succeeded
signal game_ended
signal game_error(what)

#################
# utils

func bindsg(_signal, _sub = null, obj = null, obj2 = null):
	#tree signal to self
	if obj == null:
		obj = get_tree()
	if obj2 == null:
		obj2 = self
	if _sub == null:
		_sub = "sg_%s" % _signal
	obj.connect(_signal, obj2, _sub)

func bindgs(_signal, _sub = null):
	#internal signal to self
	bindsg(_signal, _sub, self, self)

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

var _queue_attach_on_tree_change_lock = false #emits tree_change events on adding node, prevent stack overflow
func queue_attach_on_tree_change():
	if _queue_attach_on_tree_change_lock:
		return
	for p in _queue_attach:
		print("qatc: %s(%s) permanent %s" % [p, _queue_attach[p].node, _queue_attach[p].permanent])
	if get_tree():
		if get_tree().current_scene:
			var scene = get_tree().current_scene
			for p in _queue_attach:
				if _queue_attach[p].has("scene") and _queue_attach[p].scene == scene:
					continue
				var obj = scene.get_node(p)
				if obj:
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

func sg_server_log(msg):
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
	if RoleServer :
		emit_signal("network_error", "Already in server mode")
	
	server.host = host
	server.ip = IP.resolve_hostname(host, 1) #TYPE_IPV4 - ipv4 adresses only
	emit_signal("server_log", "prepare to listen on %s:%s" % [server.ip,DEFAULT_PORT])
	emit_signal("server_connecting")
	server.connection = NetworkedMultiplayerENet.new()
	server.connection.set_bind_ip(server.ip)
	var error = server.connection.create_server(DEFAULT_PORT, MAX_PEERS)
	if error == 0:
		get_tree().set_network_peer(server.connection)
		emit_signal("server_log", "server up on %s:%s" % [server.ip,DEFAULT_PORT])
		server.up = true
		bindsg("tree_changed", "server_tree_changed")
		emit_signal("server_up")
# 		emit_signal("connection_succeeded")
	else:
		emit_signal("server_log", "server error %s" % error)
		emit_signal("network_error", "failed to bring server up, error %s" % error)
# 		emit_signal("connection_failed")

func server_tree_changed():
	if not RoleServer or not server.up:
		return
	var root = get_tree()
	if root.get_network_unique_id() == 0:
		root.set_network_peer(server.connection)
		emit_signal("server_log", "reconnect server to tree")

################
#Client functions

################
# Scene functions
func change_scene(scene):
	var scenes = options.scenes
	if not scene in scenes:
		emit_signal("scene_change_error", "No such scence %s" % scene)
		emit_signal("gslog", "No such scence %s" % scene)
		return
	print("gslog", "change_scene to %s" % scene)
	
	emit_signal("gslog", "change_scene to %s" % scene)
	var error = get_tree().change_scene(scenes[scene].path)
	if error == 0 :
		emit_signal("gslog", "changing scene okay(%s)" % error)
		scenes.loaded = scene
		emit_signal("scene_change")
		emit_signal("scene_change_name", scene)
	else:
		emit_signal("gslog", "error changing scene %s" % error)

################
# Player functions

func player_toscene():
	emit_signal("gslog", "add player avatar to scene")
	var root = get_tree().current_scene
	var player = player_scene.instance()
	root.get_node("players").add_child(player)
	#player.get_node("Pivot/FPSCamera").make_current()
	emit_signal("gslog", "player_toscene: %s" % player.get_node("Pivot/FPSCamera"))

# Callback from SceneTree
func _player_connected(id):
	# This is not used in this demo, because _connected_ok is called for clients
	# on success and will do the job.
	pass

func create_player(id):
	var world = get_tree().get_root().get_child("world")
	var spawn_pos = world.get_node("spawn_points").get_child(randi()%10).translation
	var player = player_scene.instance()
	player.flies = true # MUST CHANGE WHEN COLLISIONS ARE DONE
	player.set_name(str(id)) # Use unique ID as node name
	player.translation=spawn_pos
	player.set_network_master(id) #set unique id as master

	if (id == get_tree().get_network_unique_id()):
		# If node for this peer id, set name
		player.set_player_name(player_name)
	else:
		# Otherwise set name from peer
		player.set_player_name(players[id])

		world.get_node("players").add_child(player)

# Callback from SceneTree
func _player_disconnected(id):
	if (get_tree().is_network_server()):
		if (has_node("/root/world")): # Game is in progress
			emit_signal("game_error", "Player " + players[id] + " disconnected")
			#end_game() Do not end the game
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else: # Game is not in progress
			# If we are the server, send to the new dude all the already registered players
			unregister_player(id)
			for p_id in players:
				# Erase in the server
				rpc_id(p_id, "unregister_player", id)

# Callback from SceneTree, only for clients (not server)
func _connected_ok():
	# Registration of a client beings here, tell everyone that we are here
	rpc("register_player", get_tree().get_network_unique_id(), player_name)
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
	if (get_tree().is_network_server()):
		# If we are the server, let everyone know about the new player
		rpc_id(id, "register_player", 1, player_name) # Send myself to new dude
		for p_id in players: # Then, for each remote player
			rpc_id(id, "register_player", p_id, players[p_id]) # Send player to new dude
			rpc_id(p_id, "register_player", id, new_player_name) # Send new dude to player

	players[id] = new_player_name
	emit_signal("player_list_changed")

remote func unregister_player(id):
	players.erase(id)
	emit_signal("player_list_changed")

remote func pre_start_game(spawn_points):
	# Change scene
	var world = load(WorldScene).instance()
	world.name = "world"
	get_tree().get_root().add_child(world)

	get_tree().get_root().get_node("lobby").visible = false
	get_tree().get_root().get_node("Spatial/ui").hide()

	

	for p_id in spawn_points:
		create_player(p_id)

	# Set up score (Not my case right now)
	#world.get_node("score").add_player(get_tree().get_network_unique_id(), player_name)
#	for pn in players:
#		world.get_node("score").add_player(pn, players[pn])

	if (not get_tree().is_network_server()):
		# Tell server we are ready to start
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif players.size() == 0:
		post_start_game()

remote func post_start_game():
	get_tree().set_pause(false) # Unpause and unleash the game!

var players_ready = []

remote func ready_to_start(id):
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
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")
	
	bindgs("server_log")
	bindgs("gslog")
	#bindgs("scene_change", "player_toscene")
# 	get_tree().connect("tree_changed", self, "on_scene_change_log")
	queue_attach("players", player_scene, true)
