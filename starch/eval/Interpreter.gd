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

func _init() -> void:
	global_env = EvalEnvironment.new()
	current_env = global_env
	setup_builtins()

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

var last_error: EvalError = null

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
			if not current_env.has(node.name):
				raise_error(EvalError.new(EvalError.NAME_ERROR, "name '%s' is not defined" % node.name))
				return null
			return current_env.get_var(node.name)
		
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
		
		_:
			raise_error(EvalError.new(EvalError.RUNTIME_ERROR, "Unknown node type: %s" % name))
			return null

func eval_var_declaration(node: ASTVarDeclaration):
	var value = eval(node.value) if node.value else null
	if had_error:
		return null
	
	if node.type_hint and node.type_hint != "":
		if not check_type(value, node.type_hint):
			raise_error(EvalError.new(EvalError.TYPE_ERROR, "Type mismatch: expected %s, got %s" % [node.type_hint, type_string(typeof(value))]))
			return null
	
	current_env.define(node.name, value, node.is_const)
	return null

func check_type(value, type_hint: String) -> bool:
	match type_hint:
		"str":
			return typeof(value) == TYPE_STRING
		"int":
			return typeof(value) == TYPE_INT
		"float":
			return typeof(value) in [TYPE_FLOAT, TYPE_INT]
		"bool":
			return typeof(value) == TYPE_BOOL
		"void":
			return value == null
		"array":
			return typeof(value) == TYPE_ARRAY
		"dict":
			return typeof(value) == TYPE_DICTIONARY
		_:
			return true

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
		var obj = eval(callee.object)
		if had_error:
			return null
		
		var method_name = callee.property
		
		var args = []
		for arg in node.arguments:
			args.append(eval(arg))
			if had_error:
				return null
		
		return call_method(obj, method_name, args)
	
	else:
		raise_error(EvalError.new(EvalError.TYPE_ERROR, "Cannot call non-identifier or non-member"))
		return null

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
				raise_error(EvalError.new(EvalError.TYPE_ERROR, "Parameter '%s': expected %s, got %s" % [param.name, param.type_hint, type_string(typeof(value))]))
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
			raise_error(EvalError.new(EvalError.TYPE_ERROR, "Function '%s': expected return type %s, got %s" % [func_def.name, func_def.return_type, type_string(typeof(result))]))
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
		
		if node.operator == "=":
			current_env.set_var(target_name, value)
		elif node.operator == "+=":
			var current = current_env.get_var(target_name)
			current_env.set_var(target_name, current + value)
		elif node.operator == "-=":
			var current = current_env.get_var(target_name)
			current_env.set_var(target_name, current - value)
		elif node.operator == "*=":
			var current = current_env.get_var(target_name)
			current_env.set_var(target_name, current * value)
		elif node.operator == "/=":
			var current = current_env.get_var(target_name)
			if value == 0:
				raise_error(EvalError.new(EvalError.RUNTIME_ERROR, "Division by zero"))
				return null
			current_env.set_var(target_name, current / value)
		
		return value
	
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
	
	if typeof(iterable) != TYPE_ARRAY:
		raise_error(EvalError.new(EvalError.TYPE_ERROR, "for loop requires an iterable"))
		return null
	
	var result = null
	should_break = false
	should_continue = false
	
	for item in iterable:
		# Create new scope for loop iteration
		var new_env = EvalEnvironment.new(current_env)
		new_env.define(node.variable, item, false)
		var prev_env = current_env
		current_env = new_env
		
		# Execute body without creating another scope (already in loop scope)
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
	if had_error:
		return null
	
	if typeof(obj) == TYPE_DICTIONARY:
		if node.property in obj:
			return obj[node.property]
		else:
			raise_error(EvalError.new(EvalError.KEY_ERROR, "Key '%s' not found in dictionary" % node.property))
			return null
	else:
		raise_error(EvalError.new(EvalError.ATTRIBUTE_ERROR, "Cannot access property '%s' on type %s" % [node.property, type_string(typeof(obj))]))
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
	return null

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
