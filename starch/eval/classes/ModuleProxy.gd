class_name ModuleProxy

var name: String
var module_data: Dictionary

func _init(n: String, data: Dictionary):
	name = n
	module_data = data

func _get(property):
	# Check if it's a function
	if module_data.functions.has(property):
		return module_data.functions[property]
	
	# Check if it's a class - return a constructor function
	if module_data.classes.has(property):
		var class_script = module_data.classes[property]
		# Return a callable that instantiates the class
		return func(args):
			return _instantiate_class(class_script, args)
	
	push_warning("ModuleProxy: Property '%s' not found in module '%s'" % [property, name])
	return null

func _instantiate_class(class_script: GDScript, args: Array):
	# This needs to call back into the interpreter's instantiation logic
	# We'll need to pass a reference to the interpreter
	if interpreter_ref:
		return interpreter_ref.instantiate_gdscript_class(class_script, args)
	return null

var interpreter_ref  # Add this reference when creating ModuleProxy
