class_name StarchInstance

var location: String

func _init(location: String) -> void:
	self.location = location

func run() -> void:
	var code: String = FileAccess.get_file_as_string(location)
	
	var lexer: Lexer = Lexer.new(code)
	var error: Error = lexer.lex()
	
	if error != OK:
		print("Lex Error: %s" % lexer.get_error())
	else:
		var tokens: Array[Token] = lexer.get_tokens()
		# Parsing and eval here
		var parser: Parser = Parser.new(tokens)
		
		error = parser.parse()
		
		if error != OK:
			print("Parse Error: %s" % parser.get_error())
		else:
			var program: Program = parser.get_program()
			
			var interpreter: Interpreter = Interpreter.new()
			interpreter.set_file_path("res://starch/main.starch")
			print()
			var result: EvalError = interpreter.run(program)
			
			if result.type != OK:
				print("Eval Error: %s" % result.message)
