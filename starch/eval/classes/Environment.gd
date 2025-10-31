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

func has(name: String):
	if variables.has(name):
		return true
	elif parent:
		return parent.has(name)
	else:
		return false

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
	
	# If variable exists here, update it
	if variables.has(name):
		variables[name] = value
	# Otherwise walk up parent chain
	elif parent:
		parent.set_var(name, value)
	else:
		# Variable doesn't exist anywhere, create it here
		variables[name] = value

func can_set(name: String) -> bool:
	# Check if it's a constant here
	if name in constants:
		return false
	# If variable exists here, it's settable (not const)
	if variables.has(name):
		return true
	# Check parent chain
	elif parent:
		return parent.can_set(name)
	else:
		# Doesn't exist yet, so it's settable
		return true
