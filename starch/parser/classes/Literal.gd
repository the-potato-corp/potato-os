class_name ASTLiteral extends ASTNode

var type: String
var value: Variant

func _init(type: String, value: Variant, position: Vector2i) -> void:
	super(position)
	self.type = type
	self.value = value

func serialise():
	return "Literal(%s, %s)" % [type, value]
