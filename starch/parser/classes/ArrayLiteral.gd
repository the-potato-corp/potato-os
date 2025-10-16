class_name ASTArrayLiteral extends ASTNode

var elements: Array

func _init(elements: Array, position: Vector2i) -> void:
	super(position)
	self.elements = elements

func serialise():
	var str: String = "["
	for elem in elements:
		str += elem.serialise() + ", "
	return "ArrayLiteral" + str + "]"
