extends Spatial

export(SpatialMaterial) var base_material

var pants_mat
var shirt_mat
var skin_mat
var hair_mat
var shoes_mat
var selected 

func _ready():
	pants_mat = base_material.duplicate()
	shirt_mat = base_material.duplicate()
	skin_mat = base_material.duplicate()
	hair_mat = base_material.duplicate()
	shoes_mat = base_material.duplicate()
	
	$AvatarRig/FemaleRig/Skeleton/AvatarFemale.set_surface_material(1, pants_mat)
	$AvatarRig/FemaleRig/Skeleton/AvatarFemale.set_surface_material(0, shirt_mat)
	$AvatarRig/FemaleRig/Skeleton/AvatarFemale.set_surface_material(2, skin_mat)
	$AvatarRig/FemaleRig/Skeleton/AvatarFemale.set_surface_material(4, hair_mat)
	$AvatarRig/FemaleRig/Skeleton/AvatarFemale.set_surface_material(3, shoes_mat)
	
	$AvatarRig/FemaleRig/Skeleton/AvatarMale.set_surface_material(2, pants_mat)
	$AvatarRig/FemaleRig/Skeleton/AvatarMale.set_surface_material(3, shirt_mat)
	$AvatarRig/FemaleRig/Skeleton/AvatarMale.set_surface_material(4, skin_mat)
	$AvatarRig/FemaleRig/Skeleton/AvatarMale.set_surface_material(1, hair_mat)
	$AvatarRig/FemaleRig/Skeleton/AvatarMale.set_surface_material(0, shoes_mat)

func SetColors(var pants, var shirt, var skin, var hair, var shoes):
	pants_mat.albedo_color = pants
	shirt_mat.albedo_color = shirt
	skin_mat.albedo_color = skin
	hair_mat.albedo_color = hair
	shoes_mat.albedo_color = shoes

func SetGender(var gender):
	if int(gender) == 0:
		$AvatarRig/FemaleRig/Skeleton/AvatarFemale.show()
		$AvatarRig/FemaleRig/Skeleton/AvatarMale.hide()
	else:
		$AvatarRig/FemaleRig/Skeleton/AvatarFemale.hide()
		$AvatarRig/FemaleRig/Skeleton/AvatarMale.show()