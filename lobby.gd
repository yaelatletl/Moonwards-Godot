extends Control

enum STATE {
	init,
	server_select, # waiting for sucess on server_select
	client_connect, #waiting for client connection
	last_record
}
var state = STATE.init setget set_state

func _ready():
	# Called every time the node is added to the scene.
	gamestate.connect("connection_failed", self, "_on_connection_failed")
	gamestate.connect("connection_succeeded", self, "_on_connection_success")
	gamestate.connect("player_list_changed", self, "refresh_lobby")
	gamestate.connect("game_ended", self, "_on_game_ended")
	gamestate.connect("game_error", self, "_on_game_error")

func state_hide():
	match state:
		STATE.init:
			$connect.hide()
		STATE.server_select:
			$WaitServer.hide()

func state_show():
	match state:
		STATE.init:
			$connect.show()
		STATE.server_select:
			$WaitServer/Label.text = "Setting the server up:\n"
			$WaitServer.show()

func set_state(nstate):
	state_hide()
	state = nstate
	state_show()

func sg_server_log(msg):
	$WaitServer/Label.text = "%s%s\n" % [$WaitServer/Label.text, msg]

func sg_server_up():
	var worldscene = options.scenes.default
	sg_server_log("change scene to %s" % worldscene)
	yield(get_tree().create_timer(2), "timeout")
	gamestate.change_scene(worldscene)

func sg_network_error(msg):
	set_state(STATE.init)
	$connect/error_label.text = "Error setting server : %s" % msg

func _on_host_pressed():
	self.state = STATE.server_select
	binddef = {src = gamestate, dest = self }
	bindsg("server_log")
	bindsg("server_up")
	bindsg("network_error")
	gamestate.server_set_mode()
	return

	if (get_node("connect/name").text == ""):
		get_node("connect/error_label").text="Invalid name!"
		return

	get_node("connect").hide()
	get_node("PlayersList").show()
	get_node("connect/error_label").text=""

	var player_name = get_node("connect/name").text
	gamestate.host_game(player_name)
	refresh_lobby()

func _on_join_pressed():
	if (get_node("connect/name").text == ""):
		get_node("connect/error_label").text="Invalid name!"
		return

	var ip = get_node("connect/ip").text
	if (not ip.is_valid_ip_address()):
		get_node("connect/error_label").text="Invalid IPv4 address!"
		return

	get_node("connect/error_label").text=""
	get_node("connect/host").disabled=true
	get_node("connect/join").disabled=true

	var player_name = get_node("connect/name").text
	gamestate.join_game(ip, player_name)
	# refresh_lobby() gets called by the player_list_changed signal

func _on_connection_success():
	get_node("connect").hide()
	get_node("PlayersList").show()

func _on_connection_failed():
	get_node("connect/host").disabled=false
	get_node("connect/join").disabled=false
	get_node("connect/error_label").set_text("Connection failed.")

func _on_game_ended():
	show()
	get_node("connect").show()
	get_node("PlayersList").hide()
	get_node("connect/host").disabled=false
	get_node("connect/join").disabled

func _on_game_error(errtxt):
	get_node("error").dialog_text = errtxt
	get_node("error").popup_centered_minsize()

func refresh_lobby():
	var players = gamestate.get_player_list()
	players.sort()
	get_node("PlayersList/list").clear()
	get_node("PlayersList/list").add_item(gamestate.get_player_name() + " (You)")
	for p in players:
		get_node("PlayersList/list").add_item(p)

	get_node("PlayersList/start").disabled=not get_tree().is_network_server()

func _on_start_pressed():
	gamestate.begin_game()
	hide()


func _on_Sinlgeplayer_pressed():
	gamestate.host_game("Default") #must be changed so the name is coherent between sessions. 
	gamestate.begin_game()
	hide()

	
#################
# utils
var binddef = { src = null, dest = null }
func bindsg(_signal, _sub = null):
	var obj = binddef.src
	var obj2 = binddef.dest
	#tree signal to self
	if obj == null:
		obj = get_tree()
	if obj2 == null:
		obj2 = self
	if _sub == null:
		_sub = "sg_%s" % _signal
	if not obj.is_connected(_signal, obj2, _sub):
		obj.connect(_signal, obj2, _sub)

func bindgs(_signal, _sub = null):
	var obj = binddef.src
	var obj2 = binddef.dest
	#tree signal to self
	if obj == null:
		obj = get_tree()
	if obj2 == null:
		obj2 = self
	if _sub == null:
		_sub = "sg_%s" % _signal
	if obj.is_connected(_signal, obj2, _sub):
		obj.disconnect(_signal, obj2, _sub)
