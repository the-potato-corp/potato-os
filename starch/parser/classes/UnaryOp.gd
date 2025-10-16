class_name ASTUnaryOp extends ASTNode

var operator: String
var operand: ASTNode

func _init(operator: String, operand: ASTNode, position: Vector2i) -> void:
	super(position)
	self.operator = operator
	self.operand = operand

func serialise():
	return "UnaryOp(%s, %s)" % [operator, operand.serialise()]
