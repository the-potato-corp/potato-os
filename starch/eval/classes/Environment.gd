class_name EvalEnvironment

var parent: EvalEnvironment
var variables: Dictionary = {}
var constants: Array

func _init(parent=null) -> void:
	self.parent = parent

func define(name: String, value: Variant, is_const: bool = false) -> void:
	variables[name] = value
	if is_const:
		constants.append(name)

func get_var(name: String):
	if variables.has(name):
		return variables[name]
	elif parent:
		return parent.get_var(name)
	else:
		push_error("Undefined variable: " + name)
		return null

func set_var(name: String, value: Variant) -> void:
	if name in constants:
		push_error("Cannot reassign constant: " + name)
		return
	if variables.has(name):
		variables[name] = value
