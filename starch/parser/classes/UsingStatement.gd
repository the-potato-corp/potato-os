class_name ASTUsingStatement extends ASTNode

var module: String

func _init(module: String, position: Vector2i) -> void:
	super(position)
	self.module = module

func serialise():
	return "UsingStatement(%s)" % module
