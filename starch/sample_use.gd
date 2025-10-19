extends Node

func _ready() -> void:
	var time: float = 0.0
	var code: String = FileAccess.get_file_as_string("res://starch/main.starch")
	
	time = Time.get_ticks_usec()
	var lexer: Lexer = Lexer.new(code)
	var error: Error = lexer.lex()
	print("Lexing done in %f seconds." % [(Time.get_ticks_usec() - time) / 1_000_000])
	
	if error != OK:
		print("Lex Error: %s" % lexer.get_error())
	else:
		var tokens: Array[Token] = lexer.get_tokens()
		for token in tokens:
			print("Token(%s, %s)" % [token.type, token.value])

		# Parsing and eval here
		print()
		time = Time.get_ticks_usec()
		var parser: Parser = Parser.new(tokens)
		
		error = parser.parse()
		
		print("Parsing done in %f seconds." % [(Time.get_ticks_usec() - time) / 1_000_000])
		if error != OK:
			print("Parse Error: %s" % parser.get_error())
		else:
			var program: Program = parser.get_program()
			for statement in program.statements:
				print(statement.serialise())
			print()
			
			time = Time.get_ticks_usec()
			var interpreter: Interpreter = Interpreter.new()
			var result: EvalError = interpreter.run(program)
			print("Eval done in %f seconds." % [(Time.get_ticks_usec() - time) / 1_000_000])
			if result.type != OK:
				print("Eval Error: %s" % result.message)
