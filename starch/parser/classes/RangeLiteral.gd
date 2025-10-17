class_name ASTRangeLiteral extends ASTNode

var start: ASTNode
var end: ASTNode
var step: ASTNode

func _init(start: ASTNode, end: ASTNode, step: ASTNode, position: Vector2i) -> void:
	super(position)
	
	self.start = start
	self.end = end
	self.step = step

func serialise():
	return "RangeLiteral(%s, %s, %s)" % [start.serialise(), end.serialise(), (step.serialise() if step else "")]
