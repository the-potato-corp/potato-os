class_name ASTVarDeclaration extends ASTNode

var name: String
var is_const: bool
var type_hint: String
var value: ASTNode

func _init(name: String, is_const: bool, value: ASTNode, type_hint: String, position: Vector2i) -> void:
	super(position)
	
	self.name = name
	self.is_const = is_const
	self.value = value
	self.type_hint = type_hint

func serialise():
	return "VarDeclaration(%s, %s, %s, %s)" % [name, is_const, value.serialise(), type_hint]
