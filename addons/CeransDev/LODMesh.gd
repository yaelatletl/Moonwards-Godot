extends MeshInstance
var LOD1
var LOD2
export(float)var LOD1MAX = 50 #The Maximum Distance you'll see the most detailed mesh
export(float)var LOD1MIN = 0 #Should always be 0
export(float)var LOD2MAX = 100 #Maximum Distance you'll see the low poly mesh, to be used later
export(float)var LOD2MIN = 50 #Minimum distance for the low poly mesh, should be the same as LOD1MAX
export(Mesh) var NearMesh = null
export(Mesh) var FarMesh = null 
var LOD2_visible
var LOD1_visible

func _ready():
	mesh = NearMesh

func _process(delta):
	
	var cameradist = (get_tree().get_root().get_camera().get_global_transform().origin - self.get_global_transform().origin).length()
	
	if cameradist >= LOD2MIN and cameradist <= LOD2MAX and not LOD2_visible:
		mesh = FarMesh
		LOD2_visible = true
	else:
		if LOD2_visible:
			LOD2_visible = false
			
	
	if cameradist >= LOD1MIN and cameradist <= LOD1MAX and not LOD1_visible:
		LOD1_visible = true
		mesh = NearMesh
	else: 
		if LOD1_visible:
			LOD1_visible = false 
		
		pass
