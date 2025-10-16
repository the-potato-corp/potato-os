class_name ASTIfStatement extends ASTNode

var condition: ASTNode
var then_block: Array
var elif_branches: Array
var else_block: Array

func _init(condition: ASTNode, then_block: Array, elif_branches: Array, else_block: Array, position: Vector2i) -> void:
	super(position)
	
	self.condition = condition
	self.then_block = then_block
	self.elif_branches = elif_branches
	self.else_block = else_block

func serialise():
	var then_block: String = "["
	var elif_branches: String = "["
	var else_block: String = "["
	for node in self.then_block:
		then_block += node.serialise() + ", "
	for node in self.elif_branches:
		elif_branches += node.serialise() + ", "
	for node in self.else_block:
		else_block += node.serialise() + ", "
	return "IfStatement(%s, %s], %s], %s])" % [condition.serialise(), then_block, elif_branches, else_block]
