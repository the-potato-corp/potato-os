class_name ASTParameter extends ASTNode

var name: String
var param_type: String
var default_value: ASTNode

func _init(name: String, param_type: String, default_value: ASTNode, position: Vector2i) -> void:
	super(position)
	self.name = name
	self.param_type = param_type
	self.default_value = default_value

func serialise() -> String:
	if default_value:
		return "Parameter(%s, %s, %s)" % [name, param_type, default_value.serialise()]
	else:
		return "Parameter(%s, %s)" % [name, param_type]
