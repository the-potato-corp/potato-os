class_name ASTElifBranch extends ASTNode

var condition: ASTNode
var body: Array

func _init(condition: ASTNode, body: Array, position: Vector2i) -> void:
	super(position)
	self.condition = condition
	self.body = body

func serialise() -> String:
	var body_str = "["
	for node in body:
		body_str += node.serialise() + ", "
	return "ElifBranch(%s, %s])" % [condition.serialise(), body_str]
