class_name StarchInstance

var name_class: String
var class_def: ASTClassDeclaration
var methods: Dictionary = {}
var env: EvalEnvironment

func _init(name: String, def_node: ASTClassDeclaration):
	name_class = name
	class_def = def_node

func _to_string() -> String:
	return "<STARCH instance of %s>" % name_class
