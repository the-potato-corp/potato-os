class_name ASTSliceAccess extends ASTNode

var object: ASTNode
var start: ASTNode
var end: ASTNode
var step: ASTNode

func _init(object: ASTNode, start: ASTNode, end: ASTNode, step: ASTNode, position: Vector2i) -> void:
	super(position)
	
	self.object = object
	self.start = start
	self.end = end
	self.step = step

func serialise():
	return "SliceAccess(%s, %s, %s, %s)" % [
		object.serialise(),
		start.serialise() if start else "null",
		end.serialise() if end else "null",
		step.serialise() if step else "null"
	]
