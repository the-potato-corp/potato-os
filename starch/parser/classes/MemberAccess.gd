class_name ASTMemberAccess extends ASTNode

var object: ASTNode
var member: String

func _init(object: ASTNode, member: String, position: Vector2i) -> void:
	super(position)
	
	self.object = object
	self.member = member

func serialise():
	return "MemberAccess(%s, %s)" % [object.serialise(), member]
