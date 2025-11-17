extends SceneTree
# Starch_CLI.gd - Headless entry point for the Starch interpreter
# This allows running Starch as a standalone binary for non-godot, command-line and LSP use
# the entirety of this file will contain comments for ease of understanding for others seeking to help or fix this code.
# (PLS RED IS NOT BLUE DO THIS TO YOUR OWN CODE, IM TIRED OF READING THROUGH EVERYTHING AND BUILDING IT UP IN MY BRAIN MYSELF)

class_name StarchCLI

const STARCH_VERSION = "1.0.0"
const CLI_VERSION = "1.0.0"

var exit_code: int = 0

func _initialize() -> void:
	ProjectSettings.set_setting("application/run/flush_stdout_on_print", true)

	var args = OS.get_cmdline_args() # get all arguments
	var filtered_args = []
	for arg in args:
		if not arg.begins_with("--"): # filter out all options from the real "commands"
			filtered_args.append(arg)
	
	filtered_args.erase("starch\\Starch_CLI.gd")
	
	if filtered_args.size() == 0: # if no commands were passed in, asume that they want to know help about it
		print_usage()
		quit(1)
		return
	
	var command = filtered_args[0]

	match command: #this is pretty obvious i think, it just checks what command is being run
		"run":
			if filtered_args.size() < 2:
				print("Error: No file specified")
				quit(1)
				return
			run_file(filtered_args[1])
		
		"lex":
			if filtered_args.size() < 2:
				print("Error: No file specified")
				quit(1)
				return
			lex_file(filtered_args[1])
		
		"parse":
			if filtered_args.size() < 2:
				print("Error: No file specified")
				quit(1)
				return
			parse_file(filtered_args[1])
		
		"check":
			if filtered_args.size() < 2:
				print("Error: No file specified")
				quit(1)
				return
			check_file(filtered_args[1])
		
		"lsp":
			start_lsp_server()
		
		"version":
			print("STARCH Interpreter v%s" % STARCH_VERSION)
			print("STARCH CLI v%s" % CLI_VERSION)
			print("STARCH LSP v%s" % StarchLSPServer.version)

		_:
			print("Unknown command: %s\n" % command)
	quit(exit_code)

func print_usage() -> void:
	print("STARCH Interpreter - Headless CLI\n")
	print("Usage:")
	print("  starch run <file>\t\t- Execute a Starch file")
	print("  starch lex <file>\t\t- Tokenize and display tokens")
	print("  starch parse <file>\t- Parse and display AST")
	print("  starch check <file>\t- Check syntax without executing")
	print("  starch lsp\t\t\t- Start an LSP server using stdio")
	print("  starch version\t\t- Show version information")


func run_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		print("Error: File not found: %s" % path)
		exit_code = 1
		return
	
	var runner = StarchRunner.new(path) # this makes a new starch runner, its kinda a black box to me. but i guess this is how it works
	runner.run()
	exit_code = 0
	runner = null

func lex_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		print("Error: File not found: %s" % path)
		exit_code = 1
		return
	
	var code = FileAccess.get_file_as_string(path)
	code = code.replace("\r\n", "\n") # this just cause i saw redisnotbluedev do this in his starch runner

	var lexer = Lexer.new(code) # make a lexer
	var error = lexer.lex() # then lex

	if error != OK:
		print("Lex Error: %s" % lexer.get_error())
		exit_code = 1
		lexer = null
		return

	# if great success. print the tokens
	
	var tokens = lexer.get_tokens()
	print("Tokens (%d):" % tokens.size()) 
	for token in tokens:
		print("  %s: '%s' at line %d, col %d" % [token.type, token.value, token.line, token.column])
	
	lexer = null

	exit_code = 0

func parse_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		print("Error: File not found: %s" % path)
		exit_code = 1
		return
	
	var code = FileAccess.get_file_as_string(path)
	code = code.replace("\r\n", "\n") #same reason as in the lexer

	var lexer = Lexer.new(code)
	var error = lexer.lex()

	if error != OK:
		print("Lex Error: %s" % lexer.get_error())
		exit_code = 1
		lexer = null
		return
	
	var parser = Parser.new(lexer.get_tokens())
	error = parser.parse()

	if error != OK:
		print("Parse Error: %s" % parser.get_error())
		exit_code = 1
		parser = null
		lexer = null
		return
	
	var program = parser.get_program()
	print("AST:")
	for statement in program.statements:
		print("  %s" % statement.serialise())
	
	parser = null
	lexer = null

	exit_code = 0

func check_file(path: String) -> void:
	if not FileAccess.file_exists(path):
		print("Error: File not found: %s" % path)
		exit_code = 1
		return
	
	var code = FileAccess.get_file_as_string(path)
	code = code.replace("\r\n", "\n")

	var lexer = Lexer.new(code)
	var error = lexer.lex()

	if error != OK:
		print("Lex Error: %s" % lexer.get_error())
		exit_code = 1
		lexer = null
		return

	var parser = Parser.new(lexer.get_tokens())
	error = parser.parse()

	if error != OK:
		print("Parse Error: %s" % parser.get_error())
		exit_code = 1
		parser = null
		lexer = null
		return
	
	print("Syntax is ok")

	parser = null
	lexer = null

	exit_code = 0

func start_lsp_server():
	print("Starting Starch LSP Server...")
	var lsp = StarchLSPServer.new()
	lsp.start()
