class_name ASTIndexAccess extends ASTNode

var object: ASTNode
var index: ASTNode

func _init(object: ASTNode, index: ASTNode, position: Vector2i) -> void:
	super(position)
	
	self.object = object
	self.index = index

func serialise():
	return "IndexAccess(%s, %s)" % [object.serialise(), index.serialise()]
