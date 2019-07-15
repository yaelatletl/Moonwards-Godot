extends PanelContainer

var scripts = {
	Updater = preload("res://update/scripts/Updater.gd")
}
var Updater
func AddLogMessage(var text):
	if not self.visible:
		self.visible = true
	$"HBoxContainer/TabContainer/Update log/VBoxContainer3/Panel/ScrollContainer/RichTextLabel".text += text + "\n"
	
func set_state(text):
	
	AddLogMessage(text)

func set_progress_state(text):
	var label = $"HBoxContainer/TabContainer/Update log/VBoxContainer3/Panel/ScrollContainer/RichTextLabel"
	label.text = text
	


func RunUpdateServer():
	set_progress_state("Updating server")
	$VBoxContainer/ClientStatus.visible = false
	yield(get_tree(), "idle_frame")
	yield(get_tree(), "idle_frame")
	Updater.RunUpdateServer()
	
func RunUpdateClient():
	set_progress_state("Updating client")
	yield(get_tree(), "idle_frame")
	Updater.ClientOpenConnection()
# 	Updater.RunUpdateClient()





func fn_network_ok():

	set_state("ok")

func fn_network_fail():

	set_state("fail")

func fn_server_connected():

	set_state( "connected")
	Updater.ClientCheckForServer()

func fn_server_disconnected():

	set_state( "disconnected")
	
func fn_server_fail_connecting():

	set_state( "fail")

func fn_server_online():

	set_state( "online")
	Updater.ClientCheckProtocol()
	
func fn_server_offline():

	set_state( "offline")
	
func fn_client_protocol(state):

	if state:
		set_state( "correct version")
		yield(get_tree(), "idle_frame")
		yield(get_tree(), "idle_frame")
		Updater.ClientCheckForUpdate()
	else:
		set_state("client update is required")
		Updater.ClientCloseConnection()

func fn_update_no_update():

	set_state( "up to date")
	Updater.ClientCloseConnection()

func fn_update_to_update():
	
	set_state( "update available")
	#$VBoxContainer/ClientStatus/StartUpdate.disabled = false
	Updater.ClientCloseConnection()

func fn_update_progress(percent):
	$HBoxContainer/VBoxContainer/ProgressBar.value = percent

func fn_update_finished():
	pass
func fn_error(msg):
	AddLogMessage(msg)
	pass

func _ready():
	Updater = scripts.Updater.new()
	Updater.connect("receive_update_message", self, "AddLogMessage")
	Updater.root_tree = get_tree()
	var signals = [ 
		"network_ok",
		"network_fail",
		"client_protocol",
		"server_connected",
		"server_disconnected",
		"server_fail_connecting",
		"server_online",
		"server_offline",
		"update_ok",
		"update_fail",
		"update_no_update",
		"update_progress",
		"update_finished",
		"error"
	]
	for sg in signals:
		Updater.connect(sg, self, "fn_%s" % sg)