# StarchLSPServer.gd - Language Server Protocol implementation for STARCH
# Communicates via JSON-RPC over stdin/stdout
class_name StarchLSPServer

var running: bool = false
var documents: Dictionary = {}
static var version: String = "1.0.0"

func start() -> void:
	running = true
	print_stderr("STARCH LSP Server initialized")

	while running:
		var message = read_message()
		if message:
			handle_message(message)

func read_message() -> Dictionary:
	var headers = {}

	while true: #
		var line = OS.read_string_from_stdin().strip_edges()

		if line == "":
			break
		
		var parts = line.split(":", true, 1)

		if parts.size() == 2:
			headers[parts[0].strip_edges()] = parts[1].strip_edges()
	
	if not headers.has("Content-Length"):
		return {}
	
	var content_length = int(headers["Content-Length"])

	var content = ""
	for i in range(content_length):
		content += char(OS.read_string_from_stdin().unicode_at(0))
	
	var json = JSON.new()
	var error = json.parse(content)

	if error != OK:
		print_stderr("JSON parse error: %s" % json.get_error_message())
		return {}
	
	json = null
	
	return json.data

func handle_message(message: Dictionary) -> void:
	var method = message.get("method", "")
	var id = message.get("id", null)
	var params = message.get("params", {})

	match method:
		"initialize":
			handle_initialize(id, params)
		"initialized":
			pass
		"textDocument/didOpen":
			handle_did_open(params)
		"textDocument/didChange":
			handle_did_change(params)
		"textDocument/didClose":
			handle_did_close(params)
		"textDocument/completion":
			handle_completion(id, params)
		"textDocument/hover":
			handle_hover(id, params)
		"textDocument/definition":
			handle_definition(id, params)
		"textDocument/diagnostic":
			handle_diagnostic(id, params)
		"shutdown":
			handle_shutdown(id)
		"exit":
			running = false
		_:
			if id != null:
				send_error(id, -32601, "Method not found: %s" % method)

func handle_initialize(id, _params: Dictionary) -> void:
	var response = {
		"capabilities": {
			"textDocumentSync": 1,
			"completionProvider": {
				"triggerCharacters": [".", "("]
			},
			"hoverProvider": true,
			"definitionProvider": true,
			"diagnosticProvider": {
				"interFileDependencies": false,
				"workspaceDiagnostics":  false
			}
		},
		"serverInfo": {
			"name": "Starch Language Server",
			"version": version
		}
	}

	send_response(id, response)

func handle_did_open(params: Dictionary) -> void:
	var text_document = params.get("textDocument", {})
	var uri = text_document.get("uri", "")
	var text = text_document.get("text", "")

	documents[uri] = text
	check_and_publish_diagnostics(uri, text)

func handle_did_change(params: Dictionary) -> void:
	var text_document = params.get("textDocument", {})
	var uri = text_document.get("uri", "")
	var changes = params.get("contentChanges")

	if changes.size() > 0 :
		var text = changes[0].get("text", "")
		documents[uri] = text
		check_and_publish_diagnostics(uri, text)

func handle_did_close(params: Dictionary) -> void:
	var text_document = params.get("textDocument", {})
	var uri = text_document.get("uri", "")
	documents.erase(uri)

func handle_completion(id, _params: Dictionary) -> void:
	var completions = []

	var keywords = [
		"var", "const", "function", "class", "if", "elif", "else",
		"for", "in", "while", "break", "continue", "return", "using",
		"from", "try", "catch", "raise", "and", "or", "not", "true", 
		"false", "null"
		]
	
	for keyword in keywords:
		completions.append({
			"label": keyword,
			"kind": 14, # Keyword kind
			"detail": "STARCH keyword"
		})
	
	var builtins = [
		"print", "len", "upper", "lower", "replace", "str", "int", "float",
		"bool", "type"
		]
	
	for builtin in builtins:
		completions.append({
			"label": builtin,
			"kind": 3, # Function kind
			"detail": "Built-in function"
		})
	
	send_response(id, completions)

func handle_hover(id, _params: Dictionary) -> void:
	send_response(id, null) # not implemented yet

func handle_definition(id, _params: Dictionary) -> void:
	send_response(id, null) # not implemented either, wondering how i should do these,
	# maby get red to change the parser a little to make it show where definitions are?

func handle_diagnostic(id, params: Dictionary) -> void:
	var text_document = params.get("textDocument", "")
	var uri = text_document.get("uri", "")

	var diagnostics = get_diagnostics(uri)

	send_response(id, {
		"kind": "full",
		"items": diagnostics
	})

func handle_shutdown(id) -> void:
	send_response(id, null)

func check_and_publish_diagnostics(uri: String, text: String) -> void:
	var diagnostics = []

	var lexer = Lexer.new(text)
	var error = lexer.lex()

	if error != OK:
		diagnostics.append({
			"range": {
				"start": { "line": 0, "character": 0 },
				"end": { "line": 0, "character": 0 }
			},
			"severity": 1, # error
			"message": lexer.get_error()
		})
	else:
		var parser = Parser.new(lexer.get_tokens())
		error = parser.parse()

		if error != OK:
			diagnostics.append({
				"range": {
					"start": { "line": 0, "character": 0 },
					"end": { "line": 0, "character": 0 }
				},
				"severity": 1, # error
				"message": parser.get_error()
			})
		
		parser = null
	
	send_notification("textDocument/publishDiagnostics", {
		"uri": uri,
		"diagnostics": diagnostics
	})

	lexer = null
	

func get_diagnostics(uri: String) -> Array:
	if not documents.has(uri):
		return []
	
	var text = documents[uri]
	var diagnostics = []

	var lexer = Lexer.new(text)
	var error = lexer.lex()

	if error != OK:
		diagnostics.append({
			"range": {
				"start": { "line": 0, "character": 0 },
				"end": { "line": 0, "character": 0 }
			},
			"severity": 1, # error
			"message": lexer.get_error()
		})

	else:
		var parser = Parser.new(lexer.get_tokens())
		error = parser.parse()

		if error != OK:
			diagnostics.append({
				"range": {
					"start": { "line": 0, "character": 0 },
					"end": { "line": 0, "character": 0 }
				},
				"severity": 1, # error
				"message": parser.get_error()
			})
		
		parser = null

	lexer = null

	return diagnostics

func send_response(id, result) -> void:
	var response = {
		"jsonrpc": "2.0",
		"id": id,
		"result": result
	}

	send_message(response)

func send_error(id, code: int, message: String) -> void:
	var response = {
		"jsonrpc": "2.0",
		"id":id,
		"error": {
			"code": code,
			"message": message
		}
	}

	send_message(response)

func send_notification(method: String, params: Dictionary) -> void:
	var _notification = {
		"jsonrpc": "2.0",
		"method": method,
		"params": params
	}

	send_message(_notification)

func send_message(message: Dictionary) -> void:
	var json = JSON.stringify(message)
	var content_length = json.length()

	print("Content-Length: %d\r\n\r\n%s" % [content_length, json])

func print_stderr(text: String) -> void:
	printerr("[Starch LSP] %s" % text)