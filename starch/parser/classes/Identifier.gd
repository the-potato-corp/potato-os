class_name ASTIdentifier extends ASTNode

var name: String

func _init(name: String, position: Vector2i) -> void:
	super(position)
	self.name = name

func serialise():
	return "Identifier(%s)" % name
