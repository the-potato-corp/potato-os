class_name Lexer

var code: String
var position: int = 0
var line: int = 1
var column: int = 1
var current_char: String

var _lexed: Array[Token]
var _error: String

const RESERVED: String = "\"'=-+*^/1234567890 	\n~≈<>!%()[]{},:;.,"
const KEYWORDS: Array = ["var", "const", "function", "class", "if", "elif", "else", "for", "in", "while", "break", "continue", "return", "using", "from", "try", "catch", "raise", "and", "or", "not", "as", "true", "false", "null"]

func _init(_code: String) -> void:
	code = _code
	if code.length() > 0:
		current_char = code[0]
	else:
		current_char = ""

func get_tokens() -> Array[Token]:
	return _lexed

func get_error() -> String:
	return _error

func log_text(level: String, text: String) -> void:
	match level:
		"debug":
			return
			print("[Lexer] ", text)
		"log":
			return
			print("[Lexer] ", text)
		"warn":
			push_warning("[Lexer] ", text)
		"error":
			_error = text
			push_error("[Lexer] ", text)

func advance(times: int = 1) -> void:
	for i in range(times):
		if current_char == '\n':
			line += 1
			column = 1
		else:
			column += 1
		
		position += 1
		if position < code.length():
			current_char = code[position]
		else:
			current_char = ""

func peek(offset: int=1) -> String:
	var pos: int = position + offset
	if pos >= len(code):
		return ""
	return code[pos]

func token(type: String, value: String) -> Token:
	return Token.new(type, value, line, column)

func lex() -> Error:
	var tokens: Array[Token] = []
	var comment: String = ""
	while current_char != "":
		if is_whitespace(current_char):
			if comment == "line" and current_char == "\n":
				comment = ""
				advance()
			elif not comment or "block" in comment:
				var whitespace_type: String
				match current_char:
					" ":
						whitespace_type = "Space"
					"	":
						whitespace_type = "Tab"
					"\n":
						whitespace_type = "Newline"
					_:
						whitespace_type = "Unknown (%s)" % current_char
				
				log_text("log", "Found whitespace: %s" % whitespace_type)
				advance()
			else:
				advance()  # Skip whitespace in line comments
		
		elif comment:
			# We're inside a comment, check for end or skip
			if comment == "block-html" and current_char == "-" and peek() == "-" and peek(2) == ">":
				advance(3)
				comment = ""
			elif comment == "block-star" and current_char == "*" and peek() == "/":
				advance(2)
				comment = ""
			elif comment == "line" and current_char == "\n":
				comment = ""
				advance()
			else:
				advance()

		elif current_char == "<" and peek() == "!" and peek(2) == "-" and peek(3) == "-":
			advance(4)
			comment = "block-html"

		elif current_char == "/" and peek() == "/":
			advance(2)
			comment = "line"

		elif current_char == "/" and peek() == "*":
			advance(2)
			comment = "block-star"

		elif current_char == "#":
			advance()
			comment = "line"
		
		elif is_quote(current_char):
			var text: Token = get_string_literal(current_char)
			if text:
				log_text("log", "Found string: %s" % text.value)
				tokens.append(text)
			else:
				return FAILED
		
		elif is_number(current_char):
			var number: Token = get_number()
			if number:
				log_text("log", "Found number: %s" % number.value)
				tokens.append(number)
			else:
				return FAILED
		
		elif is_operator(current_char):
			var operator: Token = get_operator()
			if operator:
				log_text("log", "Found operator: %s" % operator.value)
				tokens.append(operator)
			else:
				return FAILED
		
		elif is_identifier(current_char):
			var identifier: Token = get_identifier()
			if identifier:
				log_text("log", "Found identifier: %s" % identifier.value)
				tokens.append(identifier)
			else:
				return FAILED
		
		elif is_delimiter(current_char):
			var delimiter: Token = get_delimiter()
			if delimiter:
				log_text("log", "Found delimiter: %s" % delimiter.value)
				tokens.append(delimiter)
			else:
				return FAILED
		
		elif current_char == ";":
			tokens.append(token("Semicolon", ";"))
			advance()
		else:
			log_text("error", "Could not identify character '%s' at line %s, column %s!" % [current_char, line, column])
			return FAILED
	
	tokens.append(token("EOF", ""))
	_lexed = tokens
	return OK

func is_whitespace(character: String) -> bool:
	return character in " 	\n"

func is_quote(character: String) -> bool:
	return character in "\"'`"

func is_number(character: String, base: String ="decimal") -> bool:
	var chars: String
	match base:
		"decimal":
			chars = "1234567890"
		"binary":
			chars = "10"
		"hex":
			chars = "1234567890abcdefABCDEF"
	return character in chars

func is_operator(character: String) -> bool:
	return character in "=+*-/^~!<>"

func is_identifier(character: String) -> bool:
	return character not in RESERVED

func is_delimiter(character: String) -> bool:
	return character in "()[]{},.:"

func get_string_literal(quote_char: String) -> Token:
	advance()
	var result: String = ""
	while not current_char in ["", quote_char]:
		result += current_char
		log_text("debug", "String loop iter, curr: %s, result: %s" % [current_char, result])
		advance()
	
	advance()
	return token("String", result)

func get_number() -> Token:
	var result: String = ""
	var base: String = "decimal"
	var is_float: bool = false
	
	if current_char == "0":
		var next: String = peek()
		if next == "x":
			base = "hex"
			result = "0x"
			advance()  # consume '0'
			advance()  # consume 'x'
		elif next == "b":
			base = "binary"
			result = "0b"
			advance()  # consume '0'
			advance()  # consume 'b'
		elif next in "qwertyuiopasdfghjklzxcvbnm" and not next in "; ":
			log_text("error", "Invalid base '%s' in number literal at line %s, column %s!" % [next, line, column])
			return null
	
	# Integer part
	while is_number(current_char, base) and current_char != "":
		result += current_char
		advance()
	
	# Decimal point for floats
	if current_char == "." and peek() != ".":  # Not a range operator
		is_float = true
		result += "."
		advance()
		
		# Fractional part
		while is_number(current_char, base) and current_char != "":
			result += current_char
			advance()
	
	# Scientific notation (e.g., 2.5e10)
	if current_char in "eE":
		is_float = true
		result += current_char
		advance()
		
		if current_char in "+-":
			result += current_char
			advance()
		
		while is_number(current_char, base) and current_char != "":
			result += current_char
			advance()
	
	return token(("Float" if is_float else "Integer"), result)

func get_operator() -> Token:
	var result: String = ""
	var type: String = ""
	
	if current_char == "~" and peek() == ">":
		result = "~>" # pipeline op
		type = "Pipeline"
	elif current_char == "=" and peek() == "=":
		result = "=="
		type = "Equal"
	elif current_char == "-" and peek() == ">":
		result = "->"
		type = "Arrow"
	elif peek() == "=":
		match current_char:
			"+":
				type = "PlusAssign"
			"-":
				type = "MinusAssign"
			"*":
				type = "StarAssign"
			"/":
				type = "SlashAssign"
			"!":
				type = "NotEqual"
			"<":
				type = "LTEqual"
			">":
				type = "GTEqual"
			_:
				log_text("error", "Unexpected character '%s' at line %s, column %s!" % [current_char, line, column])
				return null
		result = current_char + "="
	else:
		match current_char:
			"+":
				type = "Plus"
			"-":
				type = "Minus"
			"*":
				type = "Star"
			"/":
				type = "Slash"
			"^":
				type = "Power"
			"%":
				type = "Percent"
			"<":
				type = "LessThan"
			">":
				type = "GreaterThan"
			"=":
				type = "Assign"
			"~":
				type = "Concatenate"
			"≈":
				type = "ApproxEqual"
		result = current_char
	
	for _i in result:
		advance()
		
	return token(type, result)

func get_identifier() -> Token:
	var result: String = ""
	
	while is_identifier(current_char) and current_char != "":
		result += current_char
		log_text("debug", "Identifier loop iter, curr: %s, result: %s" % [current_char, result])
		advance()
	
	if result in KEYWORDS:
		return token("Keyword", result)
	
	return token("Identifier", result)

func get_delimiter() -> Token:
	var type: String
	
	match current_char:
		"(":
			type = "LParen"
		")":
			type = "RParen"
		"[":
			type = "LBrack"
		"]":
			type = "RBrack"
		"{":
			type = "LBrace"
		"}":
			type = "RBrace"
		",":
			type = "Comma"
		".":
			if peek() == ".":
				type = "Range"
			else:
				type = "Dot"
		":":
			type = "Colon"
		
	if type == "Range":
		advance()
	
	var tok: Token = token(type, (".." if type == "Range" else current_char))
	advance()
	return tok
