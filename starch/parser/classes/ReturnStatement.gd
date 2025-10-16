class_name ASTReturnStatement extends ASTNode

var value: ASTNode

func _init(value: ASTNode, position: Vector2i) -> void:
	super(position)
	self.value = value

func serialise():
	return "ReturnStatement(%s)" % value.serialise()
