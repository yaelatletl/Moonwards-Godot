extends Spatial

export(SpatialMaterial) var base_material

var pants_mat
var shirt_mat
var skin_mat
var hair_mat

func _ready():
	pants_mat = base_material.duplicate()
	shirt_mat = base_material.duplicate()
	skin_mat = base_material.duplicate()
	hair_mat = base_material.duplicate()
	
	$Female/FemaleRig/Skeleton/AvatarFemale.set_surface_material(1, pants_mat)
	$Female/FemaleRig/Skeleton/AvatarFemale.set_surface_material(0, shirt_mat)
	$Female/FemaleRig/Skeleton/AvatarFemale.set_surface_material(2, skin_mat)
	$Female/FemaleRig/Skeleton/AvatarFemale.set_surface_material(3, hair_mat)
	
	$Male/MaleRig/Skeleton/AvatarMale.set_surface_material(1, pants_mat)
	$Male/MaleRig/Skeleton/AvatarMale.set_surface_material(0, shirt_mat)
	$Male/MaleRig/Skeleton/AvatarMale.set_surface_material(2, skin_mat)
	$Male/MaleRig/Skeleton/AvatarMale.set_surface_material(3, hair_mat)

func SetColors(var pants, var shirt, var skin, var hair):
	pants_mat.albedo_color = pants
	shirt_mat.albedo_color = shirt
	skin_mat.albedo_color = skin
	hair_mat.albedo_color = hair

func SetGender(var gender):
	if gender == 0:
		$Female.show()
		$Male.hide()
	else:
		$Female.hide()
		$Male.show()