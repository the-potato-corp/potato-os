class_name ASTRaiseStatement extends ASTNode

var exception: ASTNode

func _init(exception: ASTNode, position: Vector2i) -> void:
	super(position)
	self.exception = exception

func serialise():
	return "RaiseStatement(%s)" % exception.serialise()
