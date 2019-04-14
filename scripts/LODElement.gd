extends Spatial

export (NodePath) var substitute
const id = "LODElement"
func printd(s):
	utils.printdd(id, s)

var state

func _ready():
	print("LOD substitute %s of %s" % [get_path(), substitute] )
	add_to_group("LODElement", true)
	set_state()

func set_state():
	if state == null:
		save_state()
	if state == null:
		printd("fail to substitute %s %s %s" % [utils.get_node_file(self), get_path(), substitute])
	var node = get_node(substitute)
	if node.visible:
		node.visible = false
		printd("hide %s" % substitute)
	if not visible:
		visible = true
		printd("show %s" % name)
	

func save_state():
	var node = get_node(substitute)
	if node != null:
		state = {
			svisible = node.visible,
			visible = visible
		}

func restore():
	if state:
		var node = get_node(substitute)
		if node:
			if node.visible != state.svisible:
				node.visible = state.svisible
			if visible != state.visible:
				visible = state.visible
