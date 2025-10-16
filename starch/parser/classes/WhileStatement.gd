class_name ASTWhileStatement extends ASTNode

var condition: ASTNode
var body: Array

func _init(condition: ASTNode, body: Array, position: Vector2i) -> void:
	super(position)
	
	self.condition = condition
	self.body = body

func serialise():
	var body: String = "["
	for item in self.body:
		body += item.serialise() + ", "
	return "WhileStatement(%s, %s])" % [condition.serialise(), body]
