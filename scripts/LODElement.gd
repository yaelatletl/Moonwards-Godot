extends Spatial

export (NodePath) var substitute

func _ready():
	print("LOD substitute %s of %s" % [get_path(), substitute] )
	add_to_group("LODElement", true)
