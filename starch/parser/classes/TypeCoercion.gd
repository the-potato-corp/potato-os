class_name ASTTypeCoercion extends ASTNode

var expression: ASTNode
var target_type: String

func _init(expression: ASTNode, target_type: String, position: Vector2i) -> void:
	super(position)
	self.expression = expression
	self.target_type = target_type

func serialise():
	return "TypeCoersion(%s, %s)" % [expression.serialise(), target_type]
