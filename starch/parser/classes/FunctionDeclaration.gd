class_name ASTFunctionDeclaration extends ASTNode

var name: String
var parameters: Array
var body: Array
var return_type: String

func _init(name: String, parameters: Array, body: Array, return_type: String, position: Vector2i) -> void:
	super(position)
	
	self.name = name
	self.parameters = parameters
	self.body = body
	self.return_type = return_type

func serialise():
	var parameters: String = "["
	for param in self.parameters:
		parameters += param.serialise() + ", "
	var body: String = "["
	for exp in self.body:
		# what even is an exp
		body += exp.serialise() + ", "
	return "FunctionDeclaration(%s, %s], %s], %s)" % [name, parameters, body, return_type]
