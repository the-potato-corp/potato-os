class_name ASTUsingFromStatement extends ASTNode

var module: String
var names: Array

func _init(module: String, names: Array, position: Vector2i) -> void:
	super(position)
	self.module = module
	self.names = names

func serialise():
	return "UsingFromStatement(%s, %s)" % [module, str(names)]
