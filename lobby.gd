extends Control

enum STATE {
	init,
	server_select, # waiting for sucess on server_select
	client_connect, #waiting for client connection
	last_record
}
var state = STATE.init setget set_state

func set_name(name = null):
	if name == null:
		name = namelist.get_name()
	$connect/name.text = name

func _ready():
	set_name()
	# Called every time the node is added to the scene.
# 	gamestate.connect("connection_failed", self, "_on_connection_failed")
# 	gamestate.connect("connection_succeeded", self, "_on_connection_success")
# 	gamestate.connect("player_list_changed", self, "refresh_lobby")
# 	gamestate.connect("game_ended", self, "_on_game_ended")
# 	gamestate.connect("game_error", self, "_on_game_error")

func state_hide():
	match state:
		STATE.init:
			$connect.hide()
		STATE.server_select:
			$WaitServer.hide()
		STATE.client_connect:
			$WaitServer.hide()

func state_show():
	match state:
		STATE.init:
			$connect.show()
		STATE.server_select:
			$WaitServer/Label.text = "Setting the server up:\n"
			$WaitServer.show()
		STATE.client_connect:
			$WaitServer/Label.text = "Connecting to server:\n"
			$WaitServer.show()

func set_state(nstate):
	state_hide()
	state = nstate
	state_show()

func sg_network_log(msg):
	$WaitServer/Label.text = "%s%s\n" % [$WaitServer/Label.text, msg]

func sg_server_up():
	var worldscene = options.scenes.default_multiplayer_scene
	sg_network_log("change scene to %s" % worldscene)
	yield(get_tree().create_timer(2), "timeout")
	state_hide()
	gamestate.change_scene(worldscene)

func sg_network_error(msg):
	var oldstate = state
	set_state(STATE.init)
	match oldstate:
		STATE.server_select:
			$connect/error_label.text = "Error setting server : %s" % msg
		STATE.client_connect:
			$connect/error_label.text = msg

func sg_server_connected():
	sg_server_up()

func _on_host_pressed():
	if not (gamestate.RoleServer or gamestate.RoleClient):
		if ($connect/name.text == ""):
			$connect/error_label.text="Invalid name!"
			return
		var player_data = {
			username = $connect/name.text,
			gender = options.gender,
			colors = {"pants" : options.pants_color, "shirt" : options.shirt_color, "skin" : options.skin_color, "hair" : options.hair_color, "shoes" : options.shoes_color}
		}
		gamestate.player_register(player_data, true) #local player
		self.state = STATE.server_select
		binddef = {src = gamestate, dest = self }
		bindsg("network_log")
		bindsg("server_up")
		bindsg("network_error")
		gamestate.server_set_mode()
	else:
		emit_signal("network_error", "Already in server or client mode")

func _on_join_pressed():
	if not (gamestate.RoleServer or gamestate.RoleClient):
		if ($connect/name.text == ""):
			$connect/error_label.text="Invalid name!"
			return

		set_state(STATE.client_connect)
		var player_data = {
			username = $connect/name.text,
			gender = options.gender,
			colors = {"pants" : options.pants_color, "shirt" : options.shirt_color, "skin" : options.skin_color, "hair" : options.hair_color}
		}
		gamestate.player_register(player_data, true) #local player
		binddef = {src = gamestate, dest = self }
		bindsg("network_log")
		bindsg("server_connected")
		bindsg("network_error")
		gamestate.client_server_connect($connect/ip.text)
		return
	else: 
		emit_signal("network_error", "Already in server or client mode")

func _on_connection_success():
	$connect.hide()
	$PlayersList.show()

func _on_connection_failed():
	$connect/host.disabled = false
	$connect/join.disabled = false
	$connect/error_label.set_text("Connection failed.")

func _on_game_ended():
	show()
	$connect.show()
	$PlayersList.hide()
	$connect/host.disabled=false
	$connect/join.disabled

func _on_game_error(errtxt):
	$error.dialog_text = errtxt
	$error.popup_centered_minsize()

func refresh_lobby():
	var players = gamestate.get_player_list()
	players.sort()
	$PlayersList/list.clear()
	$PlayersList/list.add_item(gamestate.get_player_name() + " (You)")
	for p in players:
		$PlayersList/list.add_item(p)

	$PlayersList/start.disabled=not get_tree().is_network_server()

func _on_start_pressed():
	gamestate.begin_game()
	hide()


func _on_Sinlgeplayer_pressed():
	var worldscene = options.scenes.default_singleplayer_scene
	if (get_node("connect/name").text == ""):
		get_node("connect/error_label").text="Invalid name!"
		return
	var player_data = {
		username = $connect/name.text,
		network = false
	}
	gamestate.RoleNoNetwork = true
	gamestate.player_register(player_data, true) #local player
	sg_network_log("change scene to %s" % worldscene)
	yield(get_tree().create_timer(2), "timeout")
	state_hide()
	gamestate.change_scene(worldscene)

func _on_Button2_pressed():
	set_name()
	yield(get_tree().create_timer(0.1), "timeout")

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


