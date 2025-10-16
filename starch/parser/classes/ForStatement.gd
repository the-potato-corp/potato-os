class_name ASTForStatement extends ASTNode

var variable: String
var iterable: ASTNode
var body: Array

func _init(variable: String, iterable: ASTNode, body: Array, position: Vector2i) -> void:
	super(position)
	
	self.variable = variable
	self.iterable = iterable
	self.body = body

func serialise():
	var body: String = "["
	for node in self.body:
		body += node.serialise() + ", "
	return "ForStatement(%s, %s, %s])" % [variable, iterable.serialise(), body]
