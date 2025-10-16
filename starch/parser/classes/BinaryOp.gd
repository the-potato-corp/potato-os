class_name ASTBinaryOp extends ASTNode

var left: ASTNode
var operator: String
var right: ASTNode

func _init(left: ASTNode, operator: String, right: ASTNode, position: Vector2i) -> void:
	super(position)
	
	self.left = left
	self.operator = operator
	self.right = right

func serialise():
	return "BinaryOp(%s, %s, %s)" % [left.serialise(), operator, right.serialise()]
