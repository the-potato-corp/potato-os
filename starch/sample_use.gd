extends Node

func _ready() -> void:
	var code: String = FileAccess.get_file_as_string("res://starch/main.starch")
	var lexer: Lexer = Lexer.new(code)
	var error: Error = lexer.lex()
	if error != OK:
		print("Lex Error: %s" % lexer.get_error())
	else:
		var tokens: Array[Token] = lexer.get_tokens()
		for token in tokens:
			print("Token(%s, %s)" % [token.type, token.value])

		# Parsing and eval here
		print()
		var parser: Parser = Parser.new(tokens)
		
		error = parser.parse()
		
		if error != OK:
			print("Parse Error: %s" % parser.get_error())
		else:
			var program: Program = parser.get_program()
			for statement in program.statements:
				print(statement.serialise())
