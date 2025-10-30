class_name Interpreter

var global_env: EvalEnvironment
var current_env: EvalEnvironment
var functions: Dictionary = {}
var classes: Dictionary = {}
var had_error: bool = false
var should_break: bool = false
var should_continue: bool = false
var should_return: bool = false
var return_value = null
var last_error: EvalError = null
var current_file_path: String = ""
var loaded_modules: Dictionary = {}
var modules: Dictionary = {}
var allowed_modules: Array = []

func _init() -> void:
	global_env = EvalEnvironment.new()
	current_env = global_env
	setup_builtins()
	#print(FileAccess.get_file_as_string("user://potatofs/system/lib/gdmodules"))
	for module in FileAccess.get_file_as_string("user://potatofs/system/lib/gdmodules").split("\n"):
		allowed_modules.append(module)

func set_file_path(path: String) -> void:
	current_file_path = path

func setup_builtins() -> void:
	functions["print"] = func(args):
		if args.size() > 0:
			print(args[0])
		return null
	
	functions["len"] = func(args):
		if args.size() > 0:
			var val = args[0]
			if typeof(val) in [TYPE_STRING, TYPE_ARRAY, TYPE_DICTIONARY]:
				return val.size()
		return 0
	
	functions["upper"] = func(args):
		return str(args[0]).to_upper() if args.size() > 0 else ""
	
	functions["lower"] = func(args):
		return str(args[0]).to_lower() if args.size() > 0 else ""
	
	functions["replace"] = func(args):
		if args.size() >= 3:
			return str(args[0]).replace(str(args[1]), str(args[2]))
		return args[0] if args.size() > 0 else ""
	
	functions["str"] = func(args):
		return str(args[0]) if args.size() > 0 else ""
	
	functions["int"] = func(args):
		return int(args[0]) if args.size() > 0 else 0
	
	functions["float"] = func(args):
		return float(args[0]) if args.size() > 0 else 0.0
	
	functions["bool"] = func(args):
		return bool(args[0]) if args.size() > 0 else false
	
	functions["type"] = func(args):
		if args.size() > 0:
			return type_string(typeof(args[0]))
		return "unknown"
	
	functions["super"] = func(args):
		if not current_env.has("this"):
			raise_error(EvalError.new(EvalError.RUNTIME_ERROR, "super() can only be called from within a class method"))
			return null
		
		var instance = current_env.get_var("this")
		if not instance is StarchInstance:
			raise_error(EvalError.new(EvalError.RUNTIME_ERROR, "super() called on non-instance"))
			return null
		
		if not instance.class_def.parent or instance.class_def.parent == "":
			raise_error(EvalError.new(EvalError.RUNTIME_ERROR, "Class '%s' has no parent" % instance.name_class))
			return null
		
		if not classes.has(instance.class_def.parent):
			raise_error(EvalError.new(EvalError.NAME_ERROR, "Parent class '%s' not defined" % instance.class_def.parent))
			return null
		
		# Find parent's _init method
		var parent_class = classes[instance.class_def.parent]
		var parent_init = null
		for member in parent_class.members:
			if member is ASTFunctionDeclaration and member.name == "_init":
				parent_init = member
				break
		
		if not parent_init:
			return null
		
		# Create method environment with 'this' bound to the instance
		var method_env = EvalEnvironment.new(instance.env)
		method_env.define("this", instance, true)
		
		# Bind parameters
		for i in range(parent_init.parameters.size()):
			var param = parent_init.parameters[i]
			var value
			
			if i < args.size():
				value = args[i]
			elif param.default_value != null:
				value = eval(param.default_value)
			else:
				raise_error(EvalError.new(EvalError.TYPE_ERROR, "Missing argument for parameter: %s" % param.name))
				return null
			
			method_env.define(param.name, value, false)
		
		# Execute parent's _init
		var prev_env = current_env
		current_env = method_env
		
		for statement in parent_init.body:
			eval(statement)
			if had_error:
				break
		
		current_env = prev_env
		
		return null

func raise_error(error: EvalError) -> void:
	push_error(error.message)
	had_error = true
	last_error = error

func run(code: Program) -> EvalError:
	had_error = false
	last_error = null
	
	for node in code.statements:
		if had_error:
			break
		eval(node)
	
	if had_error:
		return last_error if last_error else EvalError.new(EvalError.RUNTIME_ERROR, "Unknown error occurred")
	return EvalError.new(OK, "Interpreting successful")

func eval(node: ASTNode):
	if not node:
		return null
	
	var script: Script = node.get_script()
	if not script:
		return null
	
	var name: String = script.get_global_name()
	
	match name:
		"ASTExpressionStatement":
			eval(node.expression)
			return null
		
		"ASTLiteral":
			return node.value
		
		"ASTIdentifier":
			# Check if it's a module name
			if modules.has(node.name):
				return modules[node.name]
			
			# Check if it's aDE function
			if functions.has(node.name):
				var func_def = functions[node.name]
				# If it's already a callable (builtin), return it
				if func_def is Callable:
					return func_def
				# Otherwise wrap user function
				return func(args):
					return call_user_function(func_def, args, null)
			
			if not current_env.has(node.name):
				raise_error(EvalError.new(EvalError.NAME_ERROR, "name '%s' is not defined" % node.name))
				return null
			var result = current_env.get_var(node.name)
			print("DEBUG Identifier '", node.name, "' = ", result, ", is wrapper? ", result is GDScriptInstanceWrapper)
			return result
		
		"ASTFunctionCall":
			return eval_function_call(node)
		
		"ASTFunctionDeclaration":
			functions[node.name] = node
			return null
		
		"ASTVarDeclaration":
			return eval_var_declaration(node)
		
		"ASTAssignment":
			return eval_assignment(node)
		
		"ASTBinaryOp":
			return eval_binary_op(node)
		
		"ASTUnaryOp":
			return eval_unary_op(node)
		
		"ASTIfStatement":
			return eval_if(node)
		
		"ASTWhileStatement":
			return eval_while(node)
		
		"ASTForStatement":
			return eval_for(node)
		
		"ASTRangeLiteral":
			return eval_range(node)
		
		"ASTArrayLiteral":
			return eval_array_literal(node)
		
		"ASTDictLiteral":
			return eval_dict_literal(node)
		
		"ASTMemberAccess":
			return eval_member_access(node)
		
		"ASTIndexAccess":
			return eval_index_access(node)
		
		"ASTSliceAccess":
			return eval_slice_access(node)
		
		"ASTBreakStatement":
			should_break = true
			return null
		
		"ASTContinueStatement":
			should_continue = true
			return null
		
		"ASTReturnStatement":
			should_return = true
			return_value = eval(node.value) if node.value else null
			return return_value
		
		"ASTRaiseStatement":
			return eval_raise(node)
		
		"ASTTryStatement":
			return eval_try(node)
		
		"ASTClassDeclaration":
			return eval_class_declaration(node)
		
		"ASTTernaryOp":
			return eval_ternary(node)
		
		"ASTUsingStatement":
			return eval_using(node)
		
		"ASTUsingFromStatement":
			return eval_using_from(node)
		
		_:
			raise_error(EvalError.new(EvalError.RUNTIME_ERROR, "Unknown node type: %s" % name))
			return null

func eval_var_declaration(node: ASTVarDeclaration):
	var value = eval(node.value) if node.value else null
	
	# DEBUG
	print("DEBUG var decl: ", node.name, " = ", typeof(value), ", is wrapper? ", value is GDScriptInstanceWrapper)
	if value is GDScriptInstanceWrapper:
		print("  Wrapper contains: ", value.gd_instance.get_class())
	
	if had_error:
		return null
	
	if node.type_hint and node.type_hint != "":
		if not check_type(value, node.type_hint):
			return null
	
	current_env.define(node.name, value, node.is_const)
	return null

func check_type(value, type_hint: String) -> bool:
	match type_hint:
		"str":
			if typeof(value) != TYPE_STRING:
				raise_error(EvalError.new(EvalError.TYPE_ERROR, "Type mismatch: expected str, got %s" % type_string(typeof(value))))
				return false
			return true
		"int":
			if typeof(value) != TYPE_INT:
				raise_error(EvalError.new(EvalError.TYPE_ERROR, "Type mismatch: expected int, got %s" % type_string(typeof(value))))
				return false
			return true
		"float":
			if typeof(value) not in [TYPE_FLOAT, TYPE_INT]:
				raise_error(EvalError.new(EvalError.TYPE_ERROR, "Type mismatch: expected float, got %s" % type_string(typeof(value))))
				return false
			return true
		"bool":
			if typeof(value) != TYPE_BOOL:
				raise_error(EvalError.new(EvalError.TYPE_ERROR, "Type mismatch: expected bool, got %s" % type_string(typeof(value))))
				return false
			return true
		"void":
			if value != null:
				raise_error(EvalError.new(EvalError.TYPE_ERROR, "Type mismatch: expected void, got %s" % type_string(typeof(value))))
				return false
			return true
		"array":
			if typeof(value) != TYPE_ARRAY:
				raise_error(EvalError.new(EvalError.TYPE_ERROR, "Type mismatch: expected array, got %s" % type_string(typeof(value))))
				return false
			return true
		"dict":
			if typeof(value) != TYPE_DICTIONARY:
				raise_error(EvalError.new(EvalError.TYPE_ERROR, "Type mismatch: expected dict, got %s" % type_string(typeof(value))))
				return false
			return true
		_:
			if classes.has(type_hint):
				if value is StarchInstance:
					if value.name_class != type_hint:
						raise_error(EvalError.new(EvalError.TYPE_ERROR, "Type mismatch: expected %s, got %s" % [type_hint, value.name_class]))
						return false
					return true
				elif value is GDScriptInstanceWrapper:
					# Assuming the type check passed if it's a GDScript wrapper instance matching the import name.
					return true 
				else:
					raise_error(EvalError.new(EvalError.TYPE_ERROR, "Type mismatch: expected %s, got %s" % [type_hint, type_string(typeof(value))]))
					return false
			raise_error(EvalError.new(EvalError.NAME_ERROR, "Type '%s' is not defined" % type_hint))
			return false

func type_string(type_id: int) -> String:
	match type_id:
		TYPE_STRING: return "str"
		TYPE_INT: return "int"
		TYPE_FLOAT: return "float"
		TYPE_BOOL: return "bool"
		TYPE_ARRAY: return "array"
		TYPE_DICTIONARY: return "dict"
		TYPE_NIL: return "void"
		_: return "unknown"

func eval_function_call(node: ASTFunctionCall):
	var callee = node.callee
	
	if callee is ASTIdentifier:
		var func_name: String = callee.name
		
		if not functions.has(func_name):
			raise_error(EvalError.new(EvalError.NAME_ERROR, "function '%s' is not defined" % func_name))
			return null
		
		var func_def = functions[func_name]
		
		var args = []
		for arg in node.arguments:
			args.append(eval(arg))
			if had_error:
				return null
		
		if func_def is Callable:
			return func_def.call(args)
		
		return call_user_function(func_def, args, node)
	
	elif callee is ASTMemberAccess:
		# First evaluate to see what we're dealing with
		var func_or_obj = eval(callee)
		#print("DEBUG eval_function_call: func_or_obj type = ", typeof(func_or_obj), ", is Callable? ", func_or_obj is Callable)
		if had_error:
			return null
		
		# Evaluate arguments
		var args = []
		for arg in node.arguments:
			args.append(eval(arg))
			if had_error:
				return null
		
		# If it's a callable (function from module or builtin), just call it
		if func_or_obj is Callable:
			print("DEBUG: Calling with args = ", args)
			var result = func_or_obj.call(args)
			print("DEBUG: Result = ", result)
			return result
		
		# If it's a user function definition, call it
		if func_or_obj is ASTFunctionDeclaration:
			return call_user_function(func_or_obj, args, node)
		
		# Otherwise it's a method call on an instance
		var obj = eval(callee.object)
		if had_error:
			return null
		
		var method_name = callee.member
		
		if obj is StarchInstance:
			return call_instance_method(obj, method_name, args)
		elif obj is GDScriptInstanceWrapper:
			return call_gdscript_method(obj.gd_instance, method_name, args)
		
		return call_method(obj, method_name, args)
	
	else:
		# Direct callable evaluation (e.g., stored function variable)
		var func_val = eval(callee)
		if had_error:
			return null
		
		if not func_val is Callable:
			raise_error(EvalError.new(EvalError.TYPE_ERROR, "Cannot call non-function value"))
			return null
		
		var args = []
		for arg in node.arguments:
			args.append(eval(arg))
			if had_error:
				return null
		
		return func_val.call(args)

func call_method(obj, method_name: String, args: Array):
	match method_name:
		"upper":
			if typeof(obj) == TYPE_STRING:
				return obj.to_upper()
		"lower":
			if typeof(obj) == TYPE_STRING:
				return obj.to_lower()
		"replace":
			if typeof(obj) == TYPE_STRING and args.size() >= 2:
				return obj.replace(str(args[0]), str(args[1]))
		"append":
			if typeof(obj) == TYPE_ARRAY and args.size() >= 1:
				obj.append(args[0])
				return null
		"pop":
			if typeof(obj) == TYPE_ARRAY:
				return obj.pop_back()
		"size":
			if typeof(obj) in [TYPE_STRING, TYPE_ARRAY, TYPE_DICTIONARY]:
				return obj.size()
		_:
			raise_error(EvalError.new(EvalError.ATTRIBUTE_ERROR, "Object has no method '%s'" % method_name))
			return null
	
	raise_error(EvalError.new(EvalError.TYPE_ERROR, "Method '%s' not supported for type %s" % [method_name, type_string(typeof(obj))]))
	return null

func call_user_function(func_def: ASTFunctionDeclaration, arguments: Array, call_node: ASTFunctionCall):
	var new_env = EvalEnvironment.new(current_env)
	
	for i in range(func_def.parameters.size()):
		var param = func_def.parameters[i]
		var value
		
		if i < arguments.size():
			value = arguments[i]
		elif param.default_value != null:
			value = eval(param.default_value)
		else:
			raise_error(EvalError.new(EvalError.TYPE_ERROR, "Missing argument for parameter: %s" % param.name))
			return null
		
		if param.type_hint and param.type_hint != "":
			if not check_type(value, param.type_hint):
				return null
		
		new_env.define(param.name, value, false)
	
	var prev_env = current_env
	current_env = new_env
	should_return = false
	return_value = null
	
	var result = null
	for statement in func_def.body:
		result = eval(statement)
		if had_error or should_break or should_continue or should_return:
			break
	
	current_env = prev_env
	
	if should_return:
		result = return_value
		should_return = false
		return_value = null
	
	if func_def.return_type and func_def.return_type != "" and func_def.return_type != "void":
		if not check_type(result, func_def.return_type):
			return null
	
	return result

func eval_assignment(node: ASTAssignment):
	var value = eval(node.value)
	if had_error:
		return null
	
	var target = node.target
	
	if target is ASTIdentifier:
		var target_name = target.name
		
		if not current_env.has(target_name):
			raise_error(EvalError.new(EvalError.NAME_ERROR, "name '%s' is not defined" % target_name))
			return null
		
		if not current_env.can_set(target_name):
			raise_error(EvalError.new(EvalError.TYPE_ERROR, "cannot reassign constant '%s'" % target_name))
			return null
		
		var current = current_env.get_var(target_name)
		
		match node.operator:
			"=": current_env.set_var(target_name, value)
			"+=": current_env.set_var(target_name, current + value)
			"-=": current_env.set_var(target_name, current - value)
			"*=": current_env.set_var(target_name, current * value)
			"/=":
				if value == 0:
					raise_error(EvalError.new(EvalError.RUNTIME_ERROR, "Division by zero"))
					return null
				current_env.set_var(target_name, current / value)
		
		return value
	
	elif target is ASTMemberAccess:
		var obj = eval(target.object)
		if had_error:
			return null
		
		var member_name = target.member
		
		if obj is StarchInstance:
			if not obj.env.has(member_name):
				raise_error(EvalError.new(EvalError.ATTRIBUTE_ERROR, "Instance of '%s' has no attribute '%s'" % [obj.name_class, member_name]))
				return null
			
			if not obj.env.can_set(member_name):
				raise_error(EvalError.new(EvalError.TYPE_ERROR, "cannot reassign constant '%s'" % member_name))
				return null
			
			var current = obj.env.get_var(member_name)

			match node.operator:
				"=": obj.env.set_var(member_name, value)
				"+=": obj.env.set_var(member_name, current + value)
				"-=": obj.env.set_var(member_name, current - value)
				"*=": obj.env.set_var(member_name, current * value)
				"/=":
					if value == 0:
						raise_error(EvalError.new(EvalError.RUNTIME_ERROR, "Division by zero"))
						return null
					obj.env.set_var(member_name, current / value)
			
			return value
		
		# PATCH START: Handle assignment to GDScriptInstanceWrapper properties
		elif obj is GDScriptInstanceWrapper:
			var gd_instance = obj.gd_instance
			
			if node.operator == "=":
				gd_instance.set(member_name, value)
			else:
				if not gd_instance.has_method("get") and not gd_instance.has(member_name):
					raise_error(EvalError.new(EvalError.ATTRIBUTE_ERROR, "GDScript instance has no attribute '%s'" % member_name))
					return null
				
				var current = gd_instance.get(member_name)
				match node.operator:
					"+=": gd_instance.set(member_name, current + value)
					"-=": gd_instance.set(member_name, current - value)
					"*=": gd_instance.set(member_name, current * value)
					"/=": 
						if value == 0:
							raise_error(EvalError.new(EvalError.RUNTIME_ERROR, "Division by zero"))
							return null
						gd_instance.set(member_name, current / value)
			return value
		# PATCH END
		
		if typeof(obj) == TYPE_DICTIONARY:
			obj[member_name] = value
			return value
		
		raise_error(EvalError.new(EvalError.TYPE_ERROR, "Cannot set property on type %s" % type_string(typeof(obj))))
		return null
	
	elif target is ASTIndexAccess:
		var obj = eval(target.object)
		if had_error:
			return null
		
		var index = eval(target.index)
		if had_error:
			return null
		
		if typeof(obj) == TYPE_ARRAY:
			if typeof(index) != TYPE_INT:
				raise_error(EvalError.new(EvalError.TYPE_ERROR, "Array index must be integer"))
				return null
			if index < 0 or index >= obj.size():
				raise_error(EvalError.new(EvalError.INDEX_ERROR, "Array index out of range"))
				return null
			obj[index] = value
		elif typeof(obj) == TYPE_DICTIONARY:
			obj[index] = value
		else:
			raise_error(EvalError.new(EvalError.TYPE_ERROR, "Cannot index type %s" % type_string(typeof(obj))))
			return null
		
		return value
	
	else:
		raise_error(EvalError.new(EvalError.TYPE_ERROR, "Invalid assignment target"))
		return null

func eval_binary_op(node: ASTBinaryOp):
	var left = eval(node.left)
	if had_error:
		return null
	
	var right = eval(node.right)
	if had_error:
		return null
	
	match node.operator:
		"+": return left + right
		"-": return left - right
		"*": return left * right
		"/":
			if right == 0:
				raise_error(EvalError.new(EvalError.RUNTIME_ERROR, "Division by zero"))
				return null
			return left / right
		"%": return left % right
		"^": return pow(left, right)
		"++": return str(left) + str(right)
		"==": return left == right
		"!=": return left != right
		"<": return left < right
		">": return left > right
		"<=": return left <= right
		">=": return left >= right
		"≈": return eval_approx_equal(left, right)
		"and": return left and right
		"or": return left or right
		"in": return eval_in_operator(left, right)
		_:
			raise_error(EvalError.new(EvalError.RUNTIME_ERROR, "Unknown operator: %s" % node.operator))
			return null

func eval_unary_op(node: ASTUnaryOp):
	var operand = eval(node.operand)
	if had_error:
		return null
	
	match node.operator:
		"-": return -operand
		"+": return +operand
		"not": return not operand
		_:
			raise_error(EvalError.new(EvalError.RUNTIME_ERROR, "Unknown unary operator: %s" % node.operator))
			return null

func eval_approx_equal(left, right) -> bool:
	if typeof(left) == TYPE_STRING and typeof(right) == TYPE_STRING:
		return left.to_lower() == right.to_lower()
	elif typeof(left) in [TYPE_FLOAT, TYPE_INT] and typeof(right) in [TYPE_FLOAT, TYPE_INT]:
		var threshold = abs(float(left)) * 0.1
		return abs(float(left) - float(right)) <= threshold
	return false

func eval_in_operator(needle, haystack) -> bool:
	if typeof(haystack) == TYPE_STRING:
		return str(needle) in haystack
	elif typeof(haystack) == TYPE_ARRAY:
		return needle in haystack
	elif typeof(haystack) == TYPE_DICTIONARY:
		return needle in haystack
	return false

func eval_if(node: ASTIfStatement):
	var condition = eval(node.condition)
	if had_error:
		return null
	
	if condition:
		return eval_block(node.then_block)
	else:
		for elif_branch in node.elif_branches:
			var elif_condition = eval(elif_branch.condition)
			if had_error:
				return null
			if elif_condition:
				return eval_block(elif_branch.then_block)
		
		if node.else_block.size() > 0:
			return eval_block(node.else_block)
	
	return null

func eval_while(node: ASTWhileStatement):
	var result = null
	should_break = false
	should_continue = false
	
	while eval(node.condition):
		if had_error:
			break
		
		result = eval_block(node.body)
		
		if had_error or should_break:
			break
		
		if should_continue:
			should_continue = false
			continue
	
	should_break = false
	should_continue = false
	return result

func eval_for(node: ASTForStatement):
	var iterable = eval(node.iterable)
	if had_error:
		return null
	
	if typeof(iterable) == TYPE_STRING:
		var chars = []
		for i in range(iterable.length()):
			chars.append(iterable[i])
		iterable = chars
	
	if typeof(iterable) != TYPE_ARRAY:
		raise_error(EvalError.new(EvalError.TYPE_ERROR, "for loop requires an iterable"))
		return null
	
	var result = null
	should_break = false
	should_continue = false
	
	for item in iterable:
		var new_env = EvalEnvironment.new(current_env)
		new_env.define(node.variable, item, false)
		var prev_env = current_env
		current_env = new_env
		
		for statement in node.body:
			result = eval(statement)
			if had_error or should_break or should_continue or should_return:
				break
		
		current_env = prev_env
		
		if had_error or should_break:
			break
		
		if should_continue:
			should_continue = false
			continue
	
	should_break = false
	should_continue = false
	return result

func eval_range(node: ASTRangeLiteral) -> Array:
	var start = eval(node.start)
	if had_error:
		return []
	
	var end = eval(node.end)
	if had_error:
		return []
	
	var step = 1
	if node.step:
		step = eval(node.step)
		if had_error:
			return []
	
	var result = []
	
	if step == 0:
		raise_error(EvalError.new(EvalError.RUNTIME_ERROR, "Range step cannot be zero"))
		return []
	
	if step > 0:
		var i = start
		while i <= end:
			result.append(i)
			i += step
	else:
		var i = start
		while i >= end:
			result.append(i)
			i += step
	
	return result

func eval_array_literal(node: ASTArrayLiteral) -> Array:
	var result = []
	for element in node.elements:
		result.append(eval(element))
		if had_error:
			return []
	return result

func eval_dict_literal(node: ASTDictLiteral) -> Dictionary:
	var result = {}
	for item in node.items:
		var key = eval(item.key)
		if had_error:
			return {}
		var value = eval(item.value)
		if had_error:
			return {}
		result[key] = value
	return result

func eval_member_access(node: ASTMemberAccess):
	var obj = eval(node.object)
	print("DEBUG member access: obj type = ", typeof(obj), ", is wrapper? ", obj is GDScriptInstanceWrapper)
	print("  Looking for member: ", node.member)
	
	if had_error:
		return null
	
	# Handle cases where the object is null
	if obj == null:
		raise_error(EvalError.new(EvalError.NULL_ERROR, "Cannot access member of a null value."))
		return null

	var member_name = node.member

	# 1. Handle ModuleProxy by dispatching to its _get method
	if obj is ModuleProxy:
		return obj._get(member_name)
	
	# 2. Handle GDScriptInstanceWrapper by dispatching to its _get method
	if obj is GDScriptInstanceWrapper:
		print("  Calling obj._get(", member_name, ")")
		var result = obj._get(member_name)
		print("  Result: ", result, ", type: ", typeof(result))
		return result

	# 3. Handle StarchInstance (your existing logic)
	if obj is StarchInstance:
		if obj.env.has(member_name):
			return obj.env.get_var(member_name)
		elif obj.methods.has(member_name):
			return StarchBoundMethod.new(obj, member_name)
		else:
			raise_error(EvalError.new(EvalError.ATTRIBUTE_ERROR, "Instance of '%s' has no attribute '%s'" % [obj.name_class, member_name]))
			return null
	
	# 4. Handle Dictionaries (your existing logic)
	if typeof(obj) == TYPE_DICTIONARY:
		if member_name in obj:
			return obj[member_name]
		else:
			raise_error(EvalError.new(EvalError.KEY_ERROR, "Key '%s' not found in dictionary" % member_name))
			return null
	
	# 5. Fallback for built-in methods on native Godot types (your existing logic)
	var method_result = call_method(obj, member_name, [])
	if not had_error:
		return method_result
	
	# If none of the above worked, the attribute does not exist.
	raise_error(EvalError.new(EvalError.ATTRIBUTE_ERROR, "Cannot access property '%s' on type %s" % [member_name, type_string(typeof(obj))]))
	return null

func eval_index_access(node: ASTIndexAccess):
	var obj = eval(node.object)
	if had_error:
		return null
	
	var index = eval(node.index)
	if had_error:
		return null
	
	if typeof(obj) == TYPE_ARRAY:
		if typeof(index) != TYPE_INT:
			raise_error(EvalError.new(EvalError.TYPE_ERROR, "Array index must be integer"))
			return null
		if index < 0 or index >= obj.size():
			raise_error(EvalError.new(EvalError.INDEX_ERROR, "Array index out of range"))
			return null
		return obj[index]
	elif typeof(obj) == TYPE_DICTIONARY:
		if index in obj:
			return obj[index]
		else:
			raise_error(EvalError.new(EvalError.KEY_ERROR, "Key not found in dictionary"))
			return null
	elif typeof(obj) == TYPE_STRING:
		if typeof(index) != TYPE_INT:
			raise_error(EvalError.new(EvalError.TYPE_ERROR, "String index must be integer"))
			return null
		if index < 0 or index >= obj.length():
			raise_error(EvalError.new(EvalError.INDEX_ERROR, "String index out of range"))
			return null
		return obj[index]
	else:
		raise_error(EvalError.new(EvalError.TYPE_ERROR, "Cannot index type %s" % type_string(typeof(obj))))
		return null

func eval_slice_access(node: ASTSliceAccess):
	var obj = eval(node.object)
	if had_error:
		return null
	
	var start = 0
	var end = 0
	var step = 1
	
	if node.start:
		start = eval(node.start)
		if had_error:
			return null
	
	if node.end:
		end = eval(node.end)
		if had_error:
			return null
	else:
		if typeof(obj) in [TYPE_ARRAY, TYPE_STRING]:
			end = obj.size() if typeof(obj) == TYPE_ARRAY else obj.length()
	
	if node.step:
		step = eval(node.step)
		if had_error:
			return null
	
	if typeof(obj) == TYPE_ARRAY:
		var result = []
		var i = start
		while (step > 0 and i < end) or (step < 0 and i > end):
			if i >= 0 and i < obj.size():
				result.append(obj[i])
			i += step
		return result
	elif typeof(obj) == TYPE_STRING:
		var result = ""
		var i = start
		while (step > 0 and i < end) or (step < 0 and i > end):
			if i >= 0 and i < obj.length():
				result += obj[i]
			i += step
		return result
	else:
		raise_error(EvalError.new(EvalError.TYPE_ERROR, "Cannot slice type %s" % type_string(typeof(obj))))
		return null

func eval_ternary(node: ASTTernaryOp):
	var condition = eval(node.condition)
	if had_error:
		return null
	
	if condition:
		return eval(node.true_value)
	else:
		return eval(node.false_value)

func eval_raise(node: ASTRaiseStatement):
	var message = eval(node.exception) if node.exception else "An error occurred"
	if had_error:
		return null
	
	raise_error(EvalError.new(EvalError.RUNTIME_ERROR, str(message)))
	return null

func eval_try(node: ASTTryStatement):
	var new_env = EvalEnvironment.new(current_env)
	var prev_env = current_env
	current_env = new_env
	
	var prev_error = had_error
	had_error = false
	
	var result = null
	for statement in node.try_block:
		result = eval(statement)
		if had_error or should_break or should_continue or should_return:
			break
	
	if had_error:
		had_error = false
		
		var catch_env = EvalEnvironment.new(prev_env)
		current_env = catch_env
		current_env.define(node.exception_var, "Error occurred", false)
		
		for statement in node.catch_block:
			result = eval(statement)
			if had_error or should_break or should_continue or should_return:
				break
	
	current_env = prev_env
	had_error = prev_error or had_error
	
	return result

func eval_class_declaration(node: ASTClassDeclaration):
	classes[node.name] = node
	functions[node.name] = func(args):
		return instantiate_class(node.name, args)
	return null

func instantiate_class(name_class: String, args: Array):
	if not classes.has(name_class):
		raise_error(EvalError.new(EvalError.NAME_ERROR, "class '%s' is not defined" % name_class))
		return null
	
	var class_def = classes[name_class]

	# PATCH START: Delegate to GDScript instantiation if class_def is a GDScript resource
	if class_def is GDScript:
		return instantiate_gdscript_class(class_def, args)
	# PATCH END
	
	var instance = StarchInstance.new(name_class, class_def)
	
	var class_env = EvalEnvironment.new(current_env)
	
	# First, inherit parent class members and methods if there's a parent
	if class_def.parent and class_def.parent != "":
		if not classes.has(class_def.parent):
			raise_error(EvalError.new(EvalError.NAME_ERROR, "Parent class '%s' is not defined" % class_def.parent))
			return null
		
		var parent_def = classes[class_def.parent]
		
		# Handle parent inheritance (assuming parent is Starch, otherwise type check needed here too)
		if parent_def is ASTClassDeclaration:
			# Inherit parent variables
			for member in parent_def.members:
				if member is ASTVarDeclaration:
					var value = eval(member.value) if member.value else null
					class_env.define(member.name, value, member.is_const)
			
			# Inherit parent methods
			for member in parent_def.members:
				if member is ASTFunctionDeclaration:
					instance.methods[member.name] = member
		else:
			raise_error(EvalError.new(EvalError.TYPE_ERROR, "Cannot inherit from non-Starch class '%s'" % class_def.parent))
			return null


	# Then add/override with current class members
	for member in class_def.members:
		if member is ASTVarDeclaration:
			var value = eval(member.value) if member.value else null
			class_env.define(member.name, value, member.is_const)
	
	for member in class_def.members:
		if member is ASTFunctionDeclaration:
			instance.methods[member.name] = member
	
	instance.env = class_env
	
	if instance.methods.has("_init"):
		call_instance_method(instance, "_init", args)
	
	return instance

func call_instance_method(instance: StarchInstance, method_name: String, args: Array):
	if not instance.methods.has(method_name):
		raise_error(EvalError.new(EvalError.ATTRIBUTE_ERROR, "Instance of '%s' has no method '%s'" % [instance.name_class, method_name]))
		return null
	
	var method_def = instance.methods[method_name]
	
	var method_env = EvalEnvironment.new(instance.env)
	
	method_env.define("this", instance, true)
	
	for i in range(method_def.parameters.size()):
		var param = method_def.parameters[i]
		var value
		
		if i < args.size():
			value = args[i]
		elif param.default_value != null:
			value = eval(param.default_value)
		else:
			raise_error(EvalError.new(EvalError.TYPE_ERROR, "Missing argument for parameter: %s" % param.name))
			return null
		
		if param.type_hint and param.type_hint != "":
			if not check_type(value, param.type_hint):
				return null
		
		method_env.define(param.name, value, false)
	
	var prev_env = current_env
	current_env = method_env
	should_return = false
	return_value = null
	
	var result = null
	for statement in method_def.body:
		result = eval(statement)
		if had_error or should_break or should_continue or should_return:
			break
	
	current_env = prev_env
	
	if should_return:
		result = return_value
		should_return = false
		return_value = null
	
	return result

func eval_block(statements: Array):
	var new_env = EvalEnvironment.new(current_env)
	var prev_env = current_env
	current_env = new_env
	
	var result = null
	for statement in statements:
		result = eval(statement)
		if had_error or should_break or should_continue or should_return:
			break
	
	current_env = prev_env
	return result

func eval_using(node: ASTUsingStatement):
	var module_name = node.module
	var module_path = resolve_module_path(module_name)
	
	if not module_path:
		raise_error(EvalError.new(EvalError.NAME_ERROR, "Module '%s' not found" % module_name))
		return null
	
	if not loaded_modules.has(module_path):
		if not load_module(module_path):
			return null
	
	# Create proxy with interpreter reference
	var proxy = ModuleProxy.new(module_name, loaded_modules[module_path])
	proxy.interpreter_ref = self  # ADD THIS
	modules[module_name] = proxy
	
	return null

func eval_using_from(node: ASTUsingFromStatement):
	var module_name = node.module
	var imports = node.names
	var module_path = resolve_module_path(module_name)
	
	if not module_path:
		raise_error(EvalError.new(EvalError.NAME_ERROR, "Module '%s' not found" % module_name))
		return null
	
	# Load the module if not already loaded
	if not loaded_modules.has(module_path):
		if not load_module(module_path):
			return null
	
	# Import specified items into global scope
	var module_data = loaded_modules[module_path]
	
	for item_name in imports:
		if module_data.functions.has(item_name):
			functions[item_name] = module_data.functions[item_name]
		elif module_data.classes.has(item_name):
			classes[item_name] = module_data.classes[item_name]
			functions[item_name] = func(args):
				return instantiate_class(item_name, args)
		else:
			raise_error(EvalError.new(EvalError.NAME_ERROR, "Module '%s' has no export '%s'" % [module_name, item_name]))
			return null
	
	return null

func instantiate_class_from_module(module_data: Dictionary, name_class: String, args: Array):
	if not module_data.classes.has(name_class):
		raise_error(EvalError.new(EvalError.NAME_ERROR, "Module has no class '%s'" % name_class))
		return null
	
	var class_def = module_data.classes[name_class]
	
	# PATCH START: Delegate to GDScript instantiation if necessary
	if class_def is GDScript:
		return instantiate_gdscript_class(class_def, args)
	# PATCH END
	
	var instance = StarchInstance.new(name_class, class_def)
	
	var class_env = EvalEnvironment.new(current_env)
	
	# Handle parent classes...
	if class_def.parent and class_def.parent != "":
		var parent_def = null
		
		# 1. Check if parent is in same module first
		if module_data.classes.has(class_def.parent):
			parent_def = module_data.classes[class_def.parent]
		# 2. Check global classes (already imported/defined)
		elif classes.has(class_def.parent):
			parent_def = classes[class_def.parent]
		
		if parent_def and parent_def is ASTClassDeclaration:
			# Inherit parent variables
			for member in parent_def.members:
				if member is ASTVarDeclaration:
					var value = eval(member.value) if member.value else null
					class_env.define(member.name, value, member.is_const)
			
			# Inherit parent methods
			for member in parent_def.members:
				if member is ASTFunctionDeclaration:
					instance.methods[member.name] = member
		elif not parent_def:
			raise_error(EvalError.new(EvalError.NAME_ERROR, "Parent class '%s' not found" % class_def.parent))
			return null
		else:
			raise_error(EvalError.new(EvalError.TYPE_ERROR, "Cannot inherit from non-Starch parent class '%s' imported from module" % class_def.parent))
			return null
	
	# Define members
	for member in class_def.members:
		if member is ASTVarDeclaration:
			var value = eval(member.value) if member.value else null
			class_env.define(member.name, value, member.is_const)
	
	for member in class_def.members:
		if member is ASTFunctionDeclaration:
			instance.methods[member.name] = member
	
	instance.env = class_env
	
	if instance.methods.has("_init"):
		call_instance_method(instance, "_init", args)
	
	return instance

func resolve_module_path(module_name: String) -> String:
	var base_dir = ""
	if current_file_path != "":
		base_dir = current_file_path.get_base_dir()
	
	var lib = "user://potatofs/system/lib"
	var bin = "user://potatofs/system/bin"
	
	var potential_paths = [
		base_dir.path_join(module_name),
		"res://" + module_name,
		lib.path_join(module_name),
		bin.path_join(module_name)
	]
	
	# Check for both .starch and .gd extensions
	for path in potential_paths:
		if FileAccess.file_exists(path):
			return path
		elif FileAccess.file_exists(path + ".starch"):
			return path + ".starch"
		elif FileAccess.file_exists(path + ".gd") and module_name in allowed_modules:
			return path + ".gd"
	
	return ""

func load_module(module_path: String) -> bool:
	# Check if it's a GDScript module
	if module_path.ends_with(".gd"):
		return load_gdscript_module(module_path)
	else:
		return load_starch_module(module_path)

func load_starch_module(module_path: String) -> bool:
	# Your existing load_module() code goes here unchanged
	var file = FileAccess.open(module_path, FileAccess.READ)
	if not file:
		raise_error(EvalError.new(EvalError.RUNTIME_ERROR, "Failed to open module file: %s" % module_path))
		return false
	
	var code = file.get_as_text()
	file.close()
	
	var lexer = Lexer.new(code)
	if lexer.lex() != OK:
		raise_error(EvalError.new(EvalError.RUNTIME_ERROR, "Failed to lex module: %s" % lexer.get_error()))
		return false
	
	var parser = Parser.new(lexer.get_tokens())
	if parser.parse() != OK:
		raise_error(EvalError.new(EvalError.RUNTIME_ERROR, "Failed to parse module: %s" % parser.get_error()))
		return false
	
	var program = parser.get_program()
	
	var module_env = EvalEnvironment.new()
	var prev_env = current_env
	var prev_file = current_file_path
	current_env = module_env
	current_file_path = module_path
	
	var prev_functions = functions.duplicate()
	var prev_classes = classes.duplicate()
	
	for statement in program.statements:
		eval(statement)
		if had_error:
			current_env = prev_env
			current_file_path = prev_file
			return false
	
	var module_data = {
		"functions": {},
		"classes": {}
	}
	
	for func_name in functions:
		if not prev_functions.has(func_name):
			module_data.functions[func_name] = functions[func_name]
	
	for name_class in classes:
		if not prev_classes.has(name_class):
			module_data.classes[name_class] = classes[name_class]
	
	functions = prev_functions
	classes = prev_classes
	current_env = prev_env
	current_file_path = prev_file
	
	loaded_modules[module_path] = module_data
	
	return true

func load_gdscript_module(module_path: String) -> bool:
	var script = load(module_path)
	if not script:
		raise_error(EvalError.new(EvalError.RUNTIME_ERROR, "Failed to load GDScript module: %s" % module_path))
		return false
	
	# Check if it's a valid GDScript
	if not script is GDScript:
		raise_error(EvalError.new(EvalError.RUNTIME_ERROR, "File is not a valid GDScript: %s" % module_path))
		return false
	
	var instance = null
	# PATCH: Check if the script can be instantiated before calling new()
	if script.can_instantiate():
		instance = script.new()
	# END PATCH
	
	var module_data = {
		"functions": {},
		"classes": {}
	}
	
	if instance:
		# Extract methods from _methods dictionary
		if instance.has_method("_get_methods") or "_methods" in instance:
			var methods = instance._methods if "_methods" in instance else instance._get_methods()
			
			if typeof(methods) == TYPE_DICTIONARY:
				for method_name in methods:
					var callable_obj = methods[method_name]
					
					if callable_obj is Callable:
						# Store a wrapper function to ensure the Starch calling convention 
						# (single array argument) is mapped correctly to the GDScript signature.
						var wrapped_callable = func(starch_args_array):
							# Starch passes one argument: the array of parameters (starch_args_array)
							
							# FIX: Pass the array of arguments directly to callv.
							# Do NOT wrap it in another array.
							if instance.has_method(method_name):
								return instance.callv(method_name, starch_args_array)
							else:
								# Fallback for bare callables (less common for module exports)
								return callable_obj.callv(starch_args_array)

						module_data.functions[method_name] = wrapped_callable
					else:
						push_warning("[Interpreter] Method '%s' in module '%s' is not callable" % [method_name, module_path])
		
		# Extract classes from _classes dictionary
		if instance.has_method("_get_classes") or "_classes" in instance:
			var classes_dict = instance._classes if "_classes" in instance else instance._get_classes()
			
			if typeof(classes_dict) == TYPE_DICTIONARY:
				for name_class in classes_dict:
					var class_script = classes_dict[name_class]
					if class_script is GDScript:
						# Store the script for later instantiation
						module_data.classes[name_class] = class_script
	
	# PATCH START: Export the GDScript file's primary class definition if available
	if script.get_name() != "":
		# We assume the main class name is the class name defined inside the file.
		module_data.classes[script.get_name()] = script
	# PATCH END
	
	loaded_modules[module_path] = module_data
	
	if instance is not RefCounted:
		instance.free()
		
	return true

func instantiate_gdscript_class(class_script: GDScript, args: Array):
	#print("DEBUG instantiate_gdscript_class: Starting with args: ", args)
	
	# Create instance - this calls _init automatically if it exists
	var instance
	if args.size() > 0:
		# Use callv to pass args to _init
		instance = class_script.callv("new", args)
	else:
		instance = class_script.new()
	
	if not instance:
		raise_error(EvalError.new(EvalError.RUNTIME_ERROR, "Failed to instantiate GDScript class"))
		return null
	
	#print("DEBUG: Created instance of type: ", instance.get_class())
	
	# Wrap it
	var wrapper = GDScriptInstanceWrapper.new(instance)
	#print("DEBUG: Created wrapper")
	
	return wrapper

func call_gdscript_method(gd_instance, method_name: String, args: Array):
	if not gd_instance.has_method(method_name):
		raise_error(EvalError.new(EvalError.ATTRIBUTE_ERROR, "GDScript instance has no method '%s'" % method_name))
		return null
	
	# Args are already evaluated, so Callables are ready to use
	return gd_instance.callv(method_name, args)
