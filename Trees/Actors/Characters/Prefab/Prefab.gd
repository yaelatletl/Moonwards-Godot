extends Spatial
var colors setget SetPuppetColors
var gender setget SetPuppetGender

var orientation = Transform()



onready var model : Spatial = $KinematicBody/Model

var is_puppet : bool = false
export(bool) var is_bot : bool = false

export(NodePath) var Character_path = ""
onready var character_node = $KinematicBody


var pants_mat
var shirt_mat
var skin_mat
var hair_mat
var shoes_mat


func _ready():
	character_node = get_node_or_null(Character_path)
	assert(character_node!=null)
	orientation = model.global_transform
	orientation.origin = Vector3()
	print("The local id is ", Lobby.local_id)
	if is_puppet:
		Options.connect("user_settings_changed", self, "ApplyUserSettings")
		SetupMaterials()
		ApplyUserSettings()
	else:
		set_process_unhandled_input(false)
	SetRemotePlayer(is_puppet)

	if is_bot and is_puppet:
		set_network_master(1)
		set_network(true)
	if is_bot and not is_puppet:
		set_network(true)
		#
		randomize()
		yield(get_tree().create_timer(1.0), "timeout")
		
	print("A player has been created with id: ", get_network_master(), " 4/4 Server Correctly set up")

func set_network(var enabled : bool) -> void:
	character_node = get_node(Character_path)
	character_node.set_network(enabled)
	#printd("Player %s enable/disable networking, nonetwork(%s)" % [get_path(), nonetwork])





func SetRemotePlayer(enable):
	is_puppet = enable
	$KinematicBody.set_player_group()
	if not is_puppet:
		$KinematicBody/Nametag.visible = false
		$Camera.current = true
	else:
		$Camera.current = false
	if is_puppet or is_bot:
		$KinematicBody/Nametag.visible = true


func SetUsername(var _username):
	$KinematicBody.username = _username
	$KinematicBody/Nametag/Viewport/Username.text = _username
	
func SetupMaterials():
	shirt_mat = $KinematicBody/Model/FemaleRig/Skeleton/AvatarFemale.get_surface_material(0).duplicate()
	pants_mat = $KinematicBody/Model/FemaleRig/Skeleton/AvatarFemale.get_surface_material(1).duplicate()
	skin_mat = $KinematicBody/Model/FemaleRig/Skeleton/AvatarFemale.get_surface_material(2).duplicate()
	shoes_mat = $KinematicBody/Model/FemaleRig/Skeleton/AvatarFemale.get_surface_material(3).duplicate()
	hair_mat = $KinematicBody/Model/FemaleRig/Skeleton/AvatarFemale.get_surface_material(3).duplicate()

	$KinematicBody/Model/FemaleRig/Skeleton/AvatarFemale.set_surface_material(0, shirt_mat)
	$KinematicBody/Model/FemaleRig/Skeleton/AvatarFemale.set_surface_material(1, pants_mat)
	$KinematicBody/Model/FemaleRig/Skeleton/AvatarFemale.set_surface_material(2, skin_mat)
	$KinematicBody/Model/FemaleRig/Skeleton/AvatarFemale.set_surface_material(3, shoes_mat)
	$KinematicBody/Model/FemaleRig/Skeleton/AvatarFemale.set_surface_material(4, hair_mat)

	$KinematicBody/Model/FemaleRig/Skeleton/AvatarMale.set_surface_material(0, shoes_mat)
	$KinematicBody/Model/FemaleRig/Skeleton/AvatarMale.set_surface_material(1, hair_mat)
	$KinematicBody/Model/FemaleRig/Skeleton/AvatarMale.set_surface_material(2, pants_mat)
	$KinematicBody/Model/FemaleRig/Skeleton/AvatarMale.set_surface_material(3, shirt_mat)
	$KinematicBody/Model/FemaleRig/Skeleton/AvatarMale.set_surface_material(4, skin_mat)

func SetPuppetColors(var colors):
	SetupMaterials()

	pants_mat.albedo_color = colors.pants
	shirt_mat.albedo_color = colors.shirt
	skin_mat.albedo_color = colors.skin
	hair_mat.albedo_color = colors.hair
	shoes_mat.albedo_color = colors.shoes

func SetPuppetGender(var gender):
	$KinematicBody/Model/FemaleRig/Skeleton/AvatarFemale.visible = (gender == Options.GENDERS.FEMALE)
	$KinematicBody/Model/FemaleRig/Skeleton/AvatarMale.visible = (gender == Options.GENDERS.MALE)

	if Options.gender == Options.GENDERS.MALE:
		$KinematicBody/Model/FemaleRig/Skeleton.scale = Vector3(1.1, 1.1, 1.1)
	else:
		$KinematicBody/Model/FemaleRig/Skeleton.scale = Vector3(1.0, 1.0, 1.0)

func ApplyUserSettings():
	pants_mat.albedo_color = Options.pants_color
	shirt_mat.albedo_color = Options.shirt_color
	skin_mat.albedo_color = Options.skin_color
	hair_mat.albedo_color = Options.hair_color
	shoes_mat.albedo_color = Options.shoes_color

	$KinematicBody/Model/FemaleRig/Skeleton/AvatarFemale.visible = (Options.gender == Options.GENDERS.FEMALE)
	$KinematicBody/Model/FemaleRig/Skeleton/AvatarMale.visible = (Options.gender == Options.GENDERS.MALE)

	if Options.gender == Options.GENDERS.MALE:
		$KinematicBody/Model/FemaleRig/Skeleton.scale = Vector3(1.1, 1.1, 1.1)
	else:
		$KinematicBody/Model/FemaleRig/Skeleton.scale = Vector3(1.0, 1.0, 1.0)

	SetUsername(Options.username)
