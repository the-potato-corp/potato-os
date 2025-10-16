class_name ASTTernaryOp extends ASTNode

var condition: ASTNode
var true_value: ASTNode
var false_value: ASTNode

func _init(condition: ASTNode, true_value: ASTNode, false_value: ASTNode, position: Vector2i) -> void:
	super(position)
	
	self.condition = condition
	self.true_value = true_value
	self.false_value = false_value

func serialise():
	return "TernaryOp(%s, %s, %s)" % [condition.serialise(), true_value.serialise(), false_value.serialise()]
