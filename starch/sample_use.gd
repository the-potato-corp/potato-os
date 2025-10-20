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
		# Parsing and eval here
		time = Time.get_ticks_usec()
		var parser: Parser = Parser.new(tokens)
		
		error = parser.parse()
		
		print("Parsing done in %f seconds." % [(Time.get_ticks_usec() - time) / 1_000_000])
		if error != OK:
			print("Parse Error: %s" % parser.get_error())
		else:
			var program: Program = parser.get_program()
			
			time = Time.get_ticks_usec()
			var interpreter: Interpreter = Interpreter.new()
			interpreter.set_file_path("res://starch/main.starch")
			print()
			var result: EvalError = interpreter.run(program)
			
			if result.type != OK:
				print("Eval Error: %s" % result.message)
			
			print()
			print("Eval done in %f seconds." % [(Time.get_ticks_usec() - time) / 1_000_000])
			
