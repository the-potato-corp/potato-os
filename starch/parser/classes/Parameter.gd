class_name ASTParameter extends ASTNode

var name: String
var type_hint: String
var default_value: ASTNode

func _init(name: String, type_hint: String, default_value: ASTNode, position: Vector2i) -> void:
	super(position)
	self.name = name
	self.type_hint = type_hint
	self.default_value = default_value

func serialise() -> String:
	if default_value:
		return "Parameter(%s, %s, %s)" % [name, type_hint, default_value.serialise()]
	else:
		return "Parameter(%s, %s)" % [name, type_hint]
