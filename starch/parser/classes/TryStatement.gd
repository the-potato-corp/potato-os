class_name ASTTryStatement extends ASTNode

var try_block: Array
var catch_variable: String
var catch_block: Array

func _init(try_block: Array, catch_variable: String, catch_block: Array, position: Vector2i) -> void:
	super(position)
	
	self.try_block = try_block
	self.catch_variable = catch_variable
	self.catch_block = catch_block

func serialise():
	var try_block: String = "["
	var catch_block: String = "["
	for node in self.try_block:
		try_block += node.serialise() + ", "
	for node in self.catch_block:
		catch_block += node.serialise() + ", "
	return "TryStatement(%s, %s, %s)" % [try_block, catch_variable, catch_block]
