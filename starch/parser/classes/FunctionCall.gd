class_name ASTFunctionCall extends ASTNode

var callee: ASTNode
var arguments: Array

func _init(callee: ASTNode, arguments: Array, position: Vector2i) -> void:
	super(position)
	self.callee = callee
	self.arguments = arguments

func serialise():
	var args: String = "["
	for arg in arguments:
		args += arg.serialise() + ", "
	return "FunctionCall(%s, %s])" % [callee.serialise(), args]
