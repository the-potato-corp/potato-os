class_name ASTExpressionStatement extends ASTNode

var expression: ASTNode

func _init(expression: ASTNode, position: Vector2i) -> void:
	super(position)
	self.expression = expression

func serialise():
	return "ExpressionStatement(%s)" % (expression.serialise() if expression else "")
