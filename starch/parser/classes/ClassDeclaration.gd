class_name ASTClassDeclaration extends ASTNode

var name: String
var parent: String
var members: Array

func _init(name: String, parent: String, members: Array, position: Vector2i) -> void:
	super(position)
	
	self.name = name
	self.parent = parent
	self.members = members

func serialise():
	var members: String = ""
	for member in self.members:
		members += member.serialise()
	return "ClassDeclaration(%s, %s, [%s])" % [name, parent, members]
