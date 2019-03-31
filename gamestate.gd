extends Node

var level_loader = preload("res://scripts/LevelLoader.gd").new()

# Default game port
const DEFAULT_PORT = 10567

# Max number of players
const MAX_PEERS = 12

# Name for my player
var username = "Username"
var world = null

# remote players in id:player_data format
var players = {}

var network_id
var local_id

#
# hold last error message
var error_msg = "Ok"
# indicate server role, mutial to client role
var RoleServer = false
#indicate client role, mutual to server role
var RoleClient = false

var RoleNoNetwork = false

#global signals
signal gslog(msg)
# network user related
signal user_join #emit when user is fully registered
signal user_leave #emit on leave of registered user
signal user_msg(id, msg) #emit message of id user
signal player_id(id) #emit id of player after establishing a connection
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
signal loading_progress(percentage)
signal loading_done
signal loading_error
signal player_scene #emit when a scene for players is detected

# Signals to let lobby GUI know what's going on
signal player_list_changed
signal connection_failed
signal connection_succeeded
signal game_ended
signal game_error(what)

# Callback from SceneTree, only for clients (not server)
func _connected_ok():
	# Registration of a client beings here, tell everyone that we are here
	rpc("register_player", get_tree().get_network_unique_id(), username)
	emit_signal("connection_succeeded")

func loading_done(var error):
	if error == OK or error == ERR_FILE_EOF:
		emit_signal("gslog", "changing scene okay(%s)" % level_loader.error)
		emit_signal("loading_done")
	else:
		emit_signal("gslog", "error changing scene %s" % level_loader.error)
		emit_signal("loading_error", "Error! " + str(error))

func _player_connected(_id):
	# This is not used in this demo, because _connected_ok is called for clients
	# on success and will do the job.
	pass

# Callback from SceneTree
func _player_disconnected(id):
	yield(get_tree(), "idle_frame")
	if get_tree().is_network_server():
		if world: # Game is in progress
			emit_signal("game_error", "Player " + players[id] + " disconnected")
		else: # Game is not in progress
			# If we are the server, send to the new dude all the already registered players
			unregister_player(id)
			for p_id in players:
				# Erase in the server
				rpc_id(p_id, "unregister_player", id)

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
	if get_tree().is_network_server():
		# If we are the server, let everyone know about the new player
		rpc_id(id, "register_player", 1, username) # Send myself to new dude
		for p_id in players: # Then, for each remote player
			rpc_id(id, "register_player", p_id, players[p_id]) # Send player to new dude
			rpc_id(p_id, "register_player", id, new_player_name) # Send new dude to player

	players[id] = new_player_name
	emit_signal("player_list_changed")

remote func unregister_player(id):
	players.erase(id)
	emit_signal("player_list_changed")

func load_level(var resource):
	# Check if the resource is valid before switching to loading screen.
	if resource is String:
		var directory = Directory.new();
		if not directory.file_exists(resource):
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

remote func pre_start_game(spawn_points):
	emit_signal("gslog", "change_scene to %s" % options.scenes.default_mutiplayer_scene)
	
	level_loader.start_loading(options.scenes[options.scenes.default_mutiplayer_scene].path)
	yield(self, "loading_done")

	world = level_loader.new_scene.instance()
	get_tree().get_root().add_child(world)
	get_tree().current_scene = world
	emit_signal("scene_change")
	
	for p_id in spawn_points:
		var spawn_pos = world.get_node("spawn_points/" + str(spawn_points[p_id])).translation
		var player = options.player_scene.instance()

		player.set_name(str(p_id)) # Use unique ID as node name
		player.translation = spawn_pos
		player.set_network_master(p_id) #set unique id as master
		
		if p_id == get_tree().get_network_unique_id():
			# If node for this peer id, set name
			player.nocamera = false
			player.set_player_name(username)
		else:
			# Otherwise set name from peer
			player.nocamera = true
			player.set_player_name(players[p_id])

		world.get_node("players").add_child(player)

	if not get_tree().is_network_server():
		# Tell server we are ready to start
		rpc_id(1, "ready_to_start", get_tree().get_network_unique_id())
	elif players.size() == 0:
		post_start_game()

remote func post_start_game():
	get_tree().set_pause(false) # Unpause and unleash the game!

var players_ready = []

remote func ready_to_start(id):
	assert(get_tree().is_network_server())

	if not id in players_ready:
		players_ready.append(id)

	if players_ready.size() == players.size():
		for p in players:
			rpc_id(p, "post_start_game")
		post_start_game()

func host_game(new_player_name):
	username = new_player_name
	var host = NetworkedMultiplayerENet.new()
	host.create_server(DEFAULT_PORT, MAX_PEERS)
	get_tree().set_network_peer(host)

func join_game(ip, new_player_name):
	username = new_player_name
	var host = NetworkedMultiplayerENet.new()
	host.create_client(ip, DEFAULT_PORT)
	get_tree().set_network_peer(host)

func get_player_list():
	return players.values()

func get_player_name():
	return username

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
	if world: # Game is in progress
		# End it
		world.queue_free()
		world = null

	emit_signal("game_ended")
	players.clear()
	get_tree().set_network_peer(null) # End networking

func _ready():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self,"_player_disconnected")
	get_tree().connect("connected_to_server", self, "_connected_ok")
	get_tree().connect("connection_failed", self, "_connected_fail")
	get_tree().connect("server_disconnected", self, "_server_disconnected")

var debug = true
var debug_id = "gamestate:: "
var debug_list = [
# 	{ enable = true, key = "" }
]
func printd(s):
	if debug:
		if debug_list.size() > 0:
			var found = false
			for dl in debug_list:
				if s.begins_with(dl.key):
					if dl.enable:
						print(debug_id, s)
					found = true
					break
			if not found:
				print(debug_id, s)
		else:
			print(debug_id, s)