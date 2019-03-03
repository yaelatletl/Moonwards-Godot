extends Object


var dimensions ##array of axis
var root

func metric(a,b):
	print("metric: ", a, " ", b)
	#FIX:
	return randf()

func Node(obj, dimension, parent):
	var node = {
		obj = obj,
		left = null,
		right = null,
		parent = null,
		dimension = dimension
	}
	return node

var dim
func sortPoints(a, b):
	if a[dimensions[dim]] < b[dimensions[dim]]:
		return true
	return false
	
func slice(array, from, to=0):
	print("slice: %s, %s" % [from, to])
	if from + 1 > array.size():
		return []
	if from < 0:
		from = array.size() + from - 1
	if from < 0:
		return []
	if to <= 0:
		to = array.size() + to - 1
	if to < from:
		return []
	if from == to:
		return [array[from]]
	
	print("slice: %s, %s" % [from, to])
	var a = array.duplicate()
	a.resize(to)
	for i in range(from):
		a.pop_front()
	
	print(a)
	return a

func buildTree(points, depth, parent):
	dim = depth % dimensions.size() #global, for custom sorting
	if points.size() == 0:
		return null
	if points.size() == 1:
		return Node(points[0], dim, parent)

	var median = floor(points.size() / 2);
	var node = Node(points[median], dim, parent);
	
	points.sort_custom(self, "sortPoints")
	node.left = buildTree(slice(points, median), depth + 1, node);
	node.right = buildTree(slice(points, median + 1), depth + 1, node);

	return node

func innerSearch(point, node, parent):
	if node == null:
		return parent
	var dimension = dimensions[node.dimension]
	if point[dimension] < node.obj[dimension]:
		return innerSearch(point, node.left, node)
	return innerSearch(point, node.right, node)

func insert(point):
	var insertPosition = innerSearch(point, root, null)
	
	if insertPosition == null:
		root = Node(point, 0, null)
		return

	var newNode = Node(point, (insertPosition.dimension + 1) % dimensions.length, insertPosition)
	var dimension = dimensions[insertPosition.dimension]

	if point[dimension] < insertPosition.obj[dimension]:
		insertPosition.left = newNode
	insertPosition.right = newNode

func nodeSearch(node, point):
	if node == null:
		return null
	if node.obj == point:
		return node
	
	var dimension = dimensions[node.dimension]
	if point[dimension] < node.obj[dimension]:
		return nodeSearch(node.left, node)
	return nodeSearch(node.right, node)


func findMin(node, dim):
	if node == null:
		return null
	
	var dimension = dimensions[dim]
	
	if node.dimension == dim:
		if node.left != null:
			return findMin(node.left, dim)
		return node

	var own = node.obj[dimension]
	var left = findMin(node.left, dim)
	var right = findMin(node.right, dim)
	var nmin = node

	if left != null and left.obj[dimension] < own:
		nmin = left;
	if right != null and right.obj[dimension] < nmin.obj[dimension]:
		nmin = right;
	return nmin;

func removeNode(node):
	var nextNode
	var nextObj

	if node.left == null and node.right == null:
		if node.parent == null:
			root = null
			return

		var pDimension = dimensions[node.parent.dimension];

		if node.obj[pDimension] < node.parent.obj[pDimension]:
			node.parent.left = null
		else:
			node.parent.right = null
		return

	# If the right subtree is not empty, swap with the minimum element on the
	# node's dimension. If it is empty, we swap the left and right subtrees and
	# do the same.
	if node.right != null:
		nextNode = findMin(node.right, node.dimension)
		nextObj = nextNode.obj
		removeNode(nextNode)
		node.obj = nextObj
	else:
		nextNode = findMin(node.left, node.dimension)
		nextObj = nextNode.obj
		removeNode(nextNode)
		node.right = node.left
		node.left = null
		node.obj = nextObj

func remove(point):
	var node = nodeSearch(root, point)
	if node == null:
		return
	removeNode(node)

var bestNodes #= []
func saveNode(node, distance):
	bestNodes.push_back([node, distance])
	if bestNodes.size() > maxNodes:
		bestNodes.pop_back()

func nearestSearch(node):
	var bestChild
	var dimension = dimensions[node.dimension]
	var ownDistance = metric(point, node.obj)
	var linearPoint = {}

	for i in range(dimensions.size()):
		if i == node.dimension:
			linearPoint[dimensions[i]] = point[dimensions[i]]
		else:
			linearPoint[dimensions[i]] = node.obj[dimensions[i]]
	
	var linearDistance = metric(linearPoint, node.obj)

	if node.right == null and node.left == null:
		if bestNodes.size() < maxNodes or ownDistance < bestNodes.peek()[1]:
			saveNode(node, ownDistance)
		return

	if node.right == null:
		bestChild = node.left
	elif node.left == null:
		bestChild = node.right
	else:
		if point[dimension] < node.obj[dimension]:
			bestChild = node.left
		else:
			bestChild = node.right

	nearestSearch(bestChild)

	if bestNodes.size() < maxNodes or ownDistance < bestNodes.peek()[1]:
		saveNode(node, ownDistance)
	
	var otherChild
	if bestNodes.size() < maxNodes or abs(linearDistance) < bestNodes.peek()[1]:
		if bestChild == node.left:
			otherChild = node.right
		else:
			otherChild = node.left
	if otherChild != null:
		nearestSearch(otherChild)

var maxNodes
var maxDistance
var point

func nearest(_point, _maxNodes, _maxDistance):
	maxNodes = _maxNodes
	maxDistance = _maxDistance
	point = _point
	var bestNodes = []
	var result = []

	if maxDistance:
		for i in range(maxNodes):
			bestNodes.push_back([null, maxDistance])

	if root:
		nearestSearch(root)

	for i in range(min(maxNodes, bestNodes.content.size())):
		if bestNodes.content[i][0]:
			result.push_back([bestNodes.content[i][0].obj, bestNodes.content[i][1]])
	return result

func height(node):
	if node == null:
		return 0
	return max(height(node.left), height(node.right)) + 1

func count(node):
	if node == null:
		return 0
	return count(node.left) + count(node.right) + 1

func balanceFactor():
	return height(root) / (log(count(root)) / log(2))

func toJSON(src=null):
	if src == null:
		src = root
	var dest = Node(src.obj, src.dimension, null)
	if src.left:
		dest.left = toJSON(src.left)
	if src.right:
		dest.right = toJSON(src.right)
	return to_json(dest)

func _init(points, dim):
	print("init kdTree, self(%s)" % self)
	print("points: ", points)
	print("dim: ", dim)
	dimensions = dim
	root = buildTree(points, 0, null)
