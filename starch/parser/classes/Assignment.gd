class_name ASTAssignment extends ASTNode

var target: ASTNode
var operator: String
var value: ASTNode

func _init(target: ASTNode, operator: String, value: ASTNode, position: Vector2i) -> void:
	super(position)
	self.target = target
	self.operator = operator
	self.value = value

func serialise():
	return "Assignment(%s, %s, %s)" % [target.serialise(), operator, value.serialise()]
