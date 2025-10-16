class_name Interpreter

var global_env: EvalEnvironment
var current_env: EvalEnvironment
var functions: Dictionary = {}

func _init() -> void:
	global_env = EvalEnvironment.new()
	current_env = global_env
	setup_builtins()

func setup_builtins() -> void:
	pass

func eval(node: ASTNode):
	var script: Script = node.get_script()
	if not script or not node:
		return null
	
	var name: String = script.get_global_name()
	match name:
		"ASTFunctionDeclaration":
			pass
