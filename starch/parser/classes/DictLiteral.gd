class_name ASTDictLiteral extends ASTNode

var pairs: Array

func _init(pairs: Array, position: Vector2i) -> void:
	super(position)
	self.pairs = pairs

func to_dict(serialise: bool = false) -> Dictionary:
	var result: Dictionary = {}
	for pair in pairs:
		result[(pair["key"].serialise() if serialise else pair["key"])] = (pair["value"].serialise() if serialise else pair["value"])
	return result

func serialise():
	return "DictLiteral" + str(to_dict(true))
