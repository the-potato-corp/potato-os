class_name Parser

var tokens: Array
var position: int = 0
var current_token: Token

var _error: String
var _program: Program

func _init(tokens: Array) -> void:
	self.tokens = tokens
	if tokens.size() > 0:
		current_token = tokens[0]
	else:
		current_token = null

func advance() -> void:
	position += 1
	if position < tokens.size():
		current_token = tokens[position]
	else:
		current_token = null

func peek(offset: int = 1) -> Token:
	var pos = position + offset
	if pos < tokens.size():
		return tokens[pos]
	return null

func get_error() -> String:
	return _error

func get_program() -> Program:
	return _program

func log_text(level: String, text: String) -> void:
	match level:
		"error":
			push_error("[Parser] ", text)
			_error = text

func parse() -> Error:
	var program: Program = Program.new([])
	
	while current_token != null and current_token.type != "EOF":
		print("DEBUG: About to parse statement, current token: ", current_token.type if current_token else "NULL", " = ", current_token.value if current_token else "")
		var statement: ASTNode = parse_statement()
		if statement:
			program.statements.append(statement)
		else:
			return FAILED
	
	_program = program
	return OK

func parse_statement() -> ASTNode:
	if not current_token:
		log_text("error", "Unexpected end of input")
		return null
	
	match current_token.type:
		"Keyword":
			match current_token.value:
				"var", "const":
					return parse_var_declaration()
				"function":
					return parse_function_declaration()
				"class":
					return parse_class_declaration()
				"if":
					return parse_if_statement()
				"for":
					return parse_for_statement()
				"while":
					return parse_while_statement()
				"return":
					return parse_return_statement()
				"break":
					return parse_break_statement()
				"continue":
					return parse_continue_statement()
				"try":
					return parse_try_statement()
				"raise":
					return parse_raise_statement()
				"using", "use":
					return parse_using_statement()
				_:
					return parse_expression_statement()
		_:
			return parse_expression_statement()

func parse_var_declaration() -> ASTNode:
	var pos = current_token.get_position()
	var is_const = current_token.value == "const"
	advance()
	
	if not current_token or current_token.type != "Identifier":
		log_text("error", "Expected identifier after '%s'" % ("const" if is_const else "var"))
		return null
	
	var name = current_token.value
	advance()
	
	var type_hint = ""
	if current_token and current_token.type == "Colon":
		advance()
		if not current_token or current_token.type != "Identifier":
			log_text("error", "Expected type name after ':'")
			return null
		type_hint = current_token.value
		advance()
	
	if not current_token or current_token.type != "Assign":
		log_text("error", "Expected '=' in variable declaration")
		return null
	advance()
	
	var value = parse_expression()
	if not value:
		return null
	
	if not current_token or current_token.type != "Semicolon":
		log_text("error", "Expected ';' after variable declaration")
		return null
	advance()
	
	return ASTVarDeclaration.new(name, is_const, value, type_hint, pos)

func parse_expression_statement() -> ASTNode:
	var expr = parse_expression()
	if not expr:
		return null
	
	if not current_token or current_token.type != "Semicolon":
		log_text("error", "Expected ';' after expression")
		return null
	advance()
	
	return ASTExpressionStatement.new(expr, expr.position)

func parse_block() -> Array:
	if not current_token or current_token.type != "LBrace":
		log_text("error", "Expected '{' to start block")
		return []
	advance()
	
	var statements: Array = []
	
	while current_token and current_token.type != "RBrace":
		var stmt = parse_statement()
		if not stmt:
			return []
		statements.append(stmt)
	
	if not current_token or current_token.type != "RBrace":
		log_text("error", "Expected '}' to close block")
		return []
	advance()
	
	return statements

func parse_if_statement() -> ASTNode:
	var pos = current_token.get_position()
	advance()
	
	var condition = parse_expression()
	if not condition:
		return null
	
	var then_block = parse_block()
	if then_block.is_empty() and _error:
		return null
	
	var elif_branches: Array = []
	var else_block: Array = []
	
	while current_token and current_token.type == "Keyword" and current_token.value == "elif":
		advance()
		
		var elif_condition = parse_expression()
		if not elif_condition:
			return null
		
		var elif_block = parse_block()
		if elif_block.is_empty() and _error:
			return null
		
		elif_branches.append(ASTElifBranch.new(elif_condition, elif_block, elif_condition.position))
	
	if current_token and current_token.type == "Keyword" and current_token.value == "else":
		advance()
		else_block = parse_block()
		if else_block.is_empty() and _error:
			return null
	
	return ASTIfStatement.new(condition, then_block, elif_branches, else_block, pos)

func parse_for_statement() -> ASTNode:
	var pos = current_token.get_position()
	advance()
	
	if not current_token or current_token.type != "Identifier":
		log_text("error", "Expected iterator variable name")
		return null
	
	var iterator_name = current_token.value
	advance()
	
	if not current_token or current_token.type != "Keyword" or current_token.value != "in":
		log_text("error", "Expected 'in' after iterator variable")
		return null
	advance()
	
	var iterable = parse_expression()
	if not iterable:
		return null
	
	var body = parse_block()
	if body.is_empty() and _error:
		return null
	
	return ASTForStatement.new(iterator_name, iterable, body, pos)

func parse_while_statement() -> ASTNode:
	var pos = current_token.get_position()
	advance()
	
	var condition = parse_expression()
	if not condition:
		return null
	
	var body = parse_block()
	if body.is_empty() and _error:
		return null
	
	return ASTWhileStatement.new(condition, body, pos)

func parse_return_statement() -> ASTNode:
	var pos = current_token.get_position()
	advance()
	
	var value: ASTNode = null
	
	if current_token and current_token.type != "Semicolon":
		value = parse_expression()
		if not value:
			return null
	
	if not current_token or current_token.type != "Semicolon":
		log_text("error", "Expected ';' after return statement")
		return null
	advance()
	
	return ASTReturnStatement.new(value, pos)

func parse_break_statement() -> ASTNode:
	var pos = current_token.get_position()
	advance()
	
	if not current_token or current_token.type != "Semicolon":
		log_text("error", "Expected ';' after 'break'")
		return null
	advance()
	
	return ASTBreakStatement.new(pos)

func parse_continue_statement() -> ASTNode:
	var pos = current_token.get_position()
	advance()
	
	if not current_token or current_token.type != "Semicolon":
		log_text("error", "Expected ';' after 'continue'")
		return null
	advance()
	
	return ASTContinueStatement.new(pos)

func parse_function_declaration() -> ASTNode:
	var pos = current_token.get_position()
	advance()
	
	if not current_token or current_token.type != "Identifier":
		log_text("error", "Expected function name")
		return null
	
	var func_name = current_token.value
	advance()
	
	if not current_token or current_token.type != "LParen":
		log_text("error", "Expected '(' after function name")
		return null
	advance()
	
	var parameters: Array = []
	
	while current_token and current_token.type != "RParen":
		if not current_token or current_token.type != "Identifier":
			log_text("error", "Expected parameter name")
			return null
		
		var param_name = current_token.value
		advance()
		
		var param_type = ""
		var default_value: ASTNode = null
		
		if current_token and current_token.type == "Colon":
			advance()
			if not current_token or current_token.type != "Identifier":
				log_text("error", "Expected type name after ':'")
				return null
			param_type = current_token.value
			advance()
		
		if current_token and current_token.type == "Keyword" and current_token.value == "or":
			advance()
			default_value = parse_expression()
			if not default_value:
				return null
		
		parameters.append(ASTParameter.new(param_name, param_type, default_value, pos))
		
		if current_token and current_token.type == "Comma":
			advance()
		elif current_token and current_token.type != "RParen":
			log_text("error", "Expected ',' or ')' in parameter list")
			return null
	
	if not current_token or current_token.type != "RParen":
		log_text("error", "Expected ')' after parameters")
		return null
	advance()
	
	var return_type = ""
	if current_token and current_token.type == "Arrow":
		advance()
		if not current_token or current_token.type not in ["Identifier", "Keyword"]:
			log_text("error", "Expected return type after '->'")
			return null
		return_type = current_token.value
		advance()
	
	var body = parse_block()
	if body.is_empty() and _error:
		return null
	
	return ASTFunctionDeclaration.new(func_name, parameters, body, return_type, pos)

func parse_class_declaration() -> ASTNode:
	var pos = current_token.get_position()
	advance()
	
	if not current_token or current_token.type != "Identifier":
		log_text("error", "Expected class name")
		return null
	
	var name_class = current_token.value
	advance()
	
	var parent = ""
	
	if current_token and current_token.type == "Colon":
		advance()
		if not current_token or current_token.type != "Identifier":
			log_text("error", "Expected parent class name after ':'")
			return null
		parent = current_token.value
		advance()
	
	if not current_token or current_token.type != "LBrace":
		log_text("error", "Expected '{' after class name")
		return null
	advance()
	
	var members: Array = []
	
	while current_token and current_token.type != "RBrace":
		if current_token.type == "Keyword" and current_token.value == "function":
			var method = parse_function_declaration()
			if not method:
				return null
			members.append(method)
		elif current_token.type == "Keyword" and current_token.value in ["var", "const"]:
			var member = parse_var_declaration()
			if not member:
				return null
			members.append(member)
		else:
			log_text("error", "Expected member variable or method in class body")
			return null
	
	if not current_token or current_token.type != "RBrace":
		log_text("error", "Expected '}' to close class body")
		return null
	advance()
	
	return ASTClassDeclaration.new(name_class, parent, members, pos)

func parse_try_statement() -> ASTNode:
	var pos = current_token.get_position()
	advance()
	
	var try_block = parse_block()
	if try_block.is_empty() and _error:
		return null
	
	if not current_token or current_token.type != "Keyword" or current_token.value != "catch":
		log_text("error", "Expected 'catch' after try block")
		return null
	advance()
	
	if not current_token or current_token.type != "LParen":
		log_text("error", "Expected '(' after 'catch'")
		return null
	advance()
	
	if not current_token or current_token.type != "Identifier":
		log_text("error", "Expected exception variable name")
		return null
	
	var exception_var = current_token.value
	advance()
	
	if not current_token or current_token.type != "RParen":
		log_text("error", "Expected ')' after exception variable")
		return null
	advance()
	
	var catch_block = parse_block()
	if catch_block.is_empty() and _error:
		return null
	
	return ASTTryStatement.new(try_block, exception_var, catch_block, pos)

func parse_raise_statement() -> ASTNode:
	var pos = current_token.get_position()
	advance()
	
	var exception = parse_expression()
	if not exception:
		return null
	
	if not current_token or current_token.type != "Semicolon":
		log_text("error", "Expected ';' after raise statement")
		return null
	advance()
	
	return ASTRaiseStatement.new(exception, pos)

func parse_using_statement() -> ASTNode:
	var pos = current_token.get_position()
	advance()
	
	if not current_token or current_token.type != "Identifier":
		log_text("error", "Expected module or item name after 'using'")
		return null
	
	var first_name = current_token.value
	advance()
	
	if current_token and current_token.type == "Keyword" and current_token.value == "from":
		advance()
		
		if not current_token or current_token.type != "Identifier":
			log_text("error", "Expected module name after 'from'")
			return null
		
		var module_name = current_token.value
		advance()
		
		if not current_token or current_token.type != "Semicolon":
			log_text("error", "Expected ';' after using statement")
			return null
		advance()
		
		return ASTUsingFromStatement.new(module_name, [first_name], pos)
	else:
		if not current_token or current_token.type != "Semicolon":
			log_text("error", "Expected ';' after using statement")
			return null
		advance()
		
		return ASTUsingStatement.new(first_name, pos)

func parse_expression() -> ASTNode:
	return parse_assignment()

func parse_primary() -> ASTNode:
	if not current_token:
		log_text("error", "Unexpected end of input")
		return null
	
	match current_token.type:
		"Integer":
			var old: Token = current_token
			advance()
			return ASTLiteral.new("int", int(old.value), old.get_position())
		"Float":
			var old: Token = current_token
			advance()
			return ASTLiteral.new("float", float(old.value), old.get_position())
		"String":
			var old: Token = current_token
			advance()
			return ASTLiteral.new("str", old.value, old.get_position())
		"Keyword":
			var old: Token = current_token
			if old.value in ["true", "false"]:
				advance()
				return ASTLiteral.new("bool", old.value == "true", old.get_position())
			elif old.value == "null":
				advance()
				return ASTLiteral.new("null", null, old.get_position())
			else:
				log_text("error", "Unexpected keyword '%s' in expression at line %s, column %s" % old.get_data())
				return null
		"Identifier":
			var old: Token = current_token
			advance()
			return ASTIdentifier.new(old.value, old.get_position())
		"LParen":
			advance()
			var expression: ASTNode = parse_expression()
			if not expression:
				return null
			if not current_token or current_token.type != "RParen":
				log_text("error", "Expected ')' but got '%s'" % (current_token.value if current_token else "EOF"))
				return null
			advance()
			return expression
		"LBrack":
			return parse_array_or_range()
		"LBrace":
			return parse_dict_literal()
		_:
			log_text("error", "Unexpected token '%s' at line %s, column %s" % current_token.get_data())
			return null

func parse_array_or_range() -> ASTNode:
	var pos: Vector2i = current_token.get_position()
	advance()
	
	if current_token and current_token.type == "RBrack":
		advance()
		return ASTArrayLiteral.new([], pos)
	
	var first_expr = parse_expression()
	if not first_expr:
		return null
	
	if not current_token:
		log_text("error", "Unexpected end of input")
		return null
	
	if current_token.type == "Range":
		advance()
		
		var end_expr = parse_expression()
		if not end_expr:
			return null
		
		var step_expr = null
		
		if current_token and current_token.type == "Range":
			advance()
			step_expr = parse_expression()
			if not step_expr:
				return null
		
		if not current_token or current_token.type != "RBrack":
			log_text("error", "Expected ']' after range")
			return null
		advance()
		
		return ASTRangeLiteral.new(first_expr, end_expr, step_expr, pos)
	
	var items: Array = [first_expr]
	
	while current_token:
		if current_token.type == "RBrack":
			advance()
			return ASTArrayLiteral.new(items, pos)
		elif current_token.type == "Comma":
			advance()
			if current_token and current_token.type == "RBrack":
				advance()
				return ASTArrayLiteral.new(items, pos)
			
			var expr = parse_expression()
			if not expr:
				return null
			items.append(expr)
		else:
			log_text("error", "Expected ',' or ']' in array literal but got '%s' at line %s, column %s" % current_token.get_data())
			return null
	
	log_text("error", "Unclosed array literal")
	return null

func parse_dict_literal() -> ASTNode:
	var pos: Vector2i = current_token.get_position()
	advance()
	var items: Array = []
	
	if current_token and current_token.type == "RBrace":
		advance()
		return ASTDictLiteral.new(items, pos)
	
	while current_token:
		var key = parse_expression()
		if not key:
			return null
		
		if not current_token or current_token.type != "Colon":
			log_text("error", "Expected ':' after dictionary key but got '%s'" % (current_token.value if current_token else "EOF"))
			return null
		advance()
		
		var value = parse_expression()
		if not value:
			return null
		
		items.append({"key": key, "value": value})
		
		if not current_token:
			log_text("error", "Unexpected end of input in dictionary literal")
			return null
		
		if current_token.type == "RBrace":
			advance()
			return ASTDictLiteral.new(items, pos)
		elif current_token.type == "Comma":
			advance()
			if current_token and current_token.type == "RBrace":
				advance()
				return ASTDictLiteral.new(items, pos)
		else:
			log_text("error", "Expected ',' or '}' in dictionary literal but got '%s' at line %s, column %s" % current_token.get_data())
			return null
	
	log_text("error", "Unclosed dictionary literal")
	return null

func parse_call() -> ASTNode:
	var expr = parse_primary()
	if not expr:
		return null
	
	while current_token:
		match current_token.type:
			"LParen":
				expr = parse_function_call(expr)
				if not expr:
					return null
			"Dot":
				expr = parse_member_access(expr)
				if not expr:
					return null
			"LBrack":
				expr = parse_index_or_slice(expr)
				if not expr:
					return null
			_:
				break
	
	return expr

func parse_member_access(object: ASTNode) -> ASTNode:
	var pos = current_token.get_position()
	advance()
	
	if not current_token or current_token.type != "Identifier":
		log_text("error", "Expected property name after '.' at line %s, column %s" % [pos.x, pos.y])
		return null
	
	var property_name = current_token.value
	advance()
	
	return ASTMemberAccess.new(object, property_name, pos)

func parse_index_or_slice(object: ASTNode) -> ASTNode:
	var pos = current_token.get_position()
	advance()
	
	if not current_token:
		log_text("error", "Unexpected end of input, expected expression or ']'")
		return null
	
	if current_token.type == "Colon":
		return parse_slice(object, null, pos)
	
	var first_expr = parse_expression()
	if not first_expr:
		return null
	
	if not current_token:
		log_text("error", "Unexpected end of input, expected ':' or ']'")
		return null
	
	if current_token.type == "Colon":
		return parse_slice(object, first_expr, pos)
	elif current_token.type == "RBrack":
		advance()
		return ASTIndexAccess.new(object, first_expr, pos)
	else:
		log_text("error", "Expected ':' or ']' but got '%s' at line %s, column %s" % current_token.get_data())
		return null

func parse_slice(object: ASTNode, start: ASTNode, pos: Vector2i) -> ASTNode:
	advance()
	
	var end: ASTNode = null
	var step: ASTNode = null
	
	if not current_token:
		log_text("error", "Unexpected end of input in slice")
		return null
	
	if current_token.type not in ["Colon", "RBrack"]:
		end = parse_expression()
		if not end:
			return null
	
	if not current_token:
		log_text("error", "Unexpected end of input in slice")
		return null
	
	if current_token.type == "Colon":
		advance()
		
		if not current_token:
			log_text("error", "Unexpected end of input in slice")
			return null
		
		if current_token.type != "RBrack":
			step = parse_expression()
			if not step:
				return null
	
	if not current_token or current_token.type != "RBrack":
		log_text("error", "Expected ']' to close slice at line %s, column %s" % [pos.x, pos.y])
		return null
	
	advance()
	
	return ASTSliceAccess.new(object, start, end, step, pos)

func parse_function_call(function: ASTNode) -> ASTNode:
	var pos = current_token.get_position()
	advance()
	
	var arguments: Array = []
	
	if not current_token:
		log_text("error", "Unexpected end of input, expected ')' or argument")
		return null
	
	if current_token.type == "RParen":
		advance()
		return ASTFunctionCall.new(function, arguments, pos)
	
	while current_token:
		var arg = parse_expression()
		if not arg:
			return null
		arguments.append(arg)
		
		if not current_token:
			log_text("error", "Unexpected end of input, expected ')' or ','")
			return null
		
		if current_token.type == "RParen":
			break
		elif current_token.type == "Comma":
			advance()
			if current_token and current_token.type == "RParen":
				break
		else:
			log_text("error", "Expected ',' or ')' but got '%s' at line %s, column %s" % current_token.get_data())
			return null
	
	if not current_token or current_token.type != "RParen":
		log_text("error", "Expected ')' to close function call")
		return null
	
	advance()
	
	return ASTFunctionCall.new(function, arguments, pos)

func parse_power() -> ASTNode:
	var left = parse_call()
	if not left:
		return null
	
	if current_token and current_token.type == "Power":
		var pos = current_token.get_position()
		advance()
		var right = parse_power()
		if not right:
			return null
		return ASTBinaryOp.new(left, "^", right, pos)
	
	return left

func parse_unary() -> ASTNode:
	if current_token and current_token.type in ["Keyword", "Plus", "Minus"]:
		if (current_token.type == "Keyword" and current_token.value == "not") or \
		   (current_token.type in ["Plus", "Minus"] and current_token.value in ["-", "+"]):
			var pos = current_token.get_position()
			var op = current_token.value
			advance()
			
			var operand = parse_unary()
			if not operand:
				return null
			
			return ASTUnaryOp.new(op, operand, pos)
	
	return parse_power()

func parse_factor() -> ASTNode:
	var left = parse_unary()
	if not left:
		return null
	
	while current_token and current_token.type in ["Star", "Slash", "Percent"]:
		var pos = current_token.get_position()
		var op = current_token.value
		advance()
		
		var right = parse_unary()
		if not right:
			return null
		
		left = ASTBinaryOp.new(left, op, right, pos)
	
	return left

func parse_term() -> ASTNode:
	var left = parse_factor()
	if not left:
		return null
	
	while current_token and current_token.type in ["Plus", "Minus", "Concatenate"]:
		var pos = current_token.get_position()
		var op = current_token.value
		advance()
		
		var right = parse_factor()
		if not right:
			return null
		
		left = ASTBinaryOp.new(left, op, right, pos)
	
	return left

func parse_comparison() -> ASTNode:
	var left = parse_term()
	if not left:
		return null
	
	while current_token and current_token.type in ["LessThan", "GreaterThan", "LTEqual", "GTEqual"]:
		var pos = current_token.get_position()
		var op = current_token.value
		advance()
		
		var right = parse_term()
		if not right:
			return null
		
		left = ASTBinaryOp.new(left, op, right, pos)
	
	return left

func parse_equality() -> ASTNode:
	var left = parse_comparison()
	if not left:
		return null
	
	while current_token and current_token.type in ["Equal", "NotEqual", "ApproxEqual"]:
		var pos = current_token.get_position()
		var op = current_token.value
		advance()
		
		var right = parse_comparison()
		if not right:
			return null
		
		left = ASTBinaryOp.new(left, op, right, pos)
	
	return left

func parse_and() -> ASTNode:
	var left = parse_equality()
	if not left:
		return null
	
	while current_token and current_token.type == "Keyword" and current_token.value == "and":
		var pos = current_token.get_position()
		var op = current_token.value
		advance()
		
		var right = parse_equality()
		if not right:
			return null
		
		left = ASTBinaryOp.new(left, op, right, pos)
	
	return left

func parse_or() -> ASTNode:
	var left = parse_and()
	if not left:
		return null
	
	while current_token and current_token.type == "Keyword" and current_token.value == "or":
		var pos = current_token.get_position()
		var op = current_token.value
		advance()
		
		var right = parse_and()
		if not right:
			return null
		
		left = ASTBinaryOp.new(left, op, right, pos)
	
	return left

func parse_pipeline() -> ASTNode:
	var left = parse_or()
	if not left:
		return null
	
	while current_token and current_token.type == "Pipeline":
		advance()
		
		if current_token and current_token.type == "Dot":
			advance()
			
			if not current_token or current_token.type != "Identifier":
				log_text("error", "Expected method name after '.' in pipeline")
				return null
			
			var method_name = current_token.value
			var pos = current_token.get_position()
			advance()
			
			if not current_token or current_token.type != "LParen":
				log_text("error", "Expected '()' after method name in pipeline")
				return null
			
			var member = ASTMemberAccess.new(left, method_name, pos)
			left = parse_function_call(member)
			if not left:
				return null
		else:
			var right = parse_or()
			if not right:
				return null
			
			if right is ASTFunctionCall:
				right.arguments.insert(0, left)
				left = right
			else:
				log_text("error", "Pipeline operator requires function call on right side")
				return null
	
	return left

func parse_ternary() -> ASTNode:
	var left = parse_pipeline()
	if not left:
		return null
	
	if current_token and current_token.type == "Keyword" and current_token.value == "if":
		var start: Token = current_token
		advance()
		
		var condition = parse_pipeline()
		if not condition:
			return null
		
		if not current_token or current_token.type != "Keyword" or current_token.value != "else":
			log_text("error", "Expected 'else' in ternary expression")
			return null
		advance()
		
		var false_value = parse_pipeline()
		if not false_value:
			return null
		
		return ASTTernaryOp.new(condition, left, false_value, start.get_position())
	
	return left

func parse_assignment() -> ASTNode:
	var left = parse_ternary()
	if not left:
		return null
	
	if current_token and current_token.type in ["Assign", "PlusAssign", "MinusAssign", "StarAssign", "SlashAssign"]:
		var pos = current_token.get_position()
		var op = current_token.value
		advance()
		
		var right = parse_assignment()
		if not right:
			return null
		
		return ASTAssignment.new(left, op, right, pos)
	
	return left
