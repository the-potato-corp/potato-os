@abstract class_name ASTNode

var line: int
var column: int
var position: Vector2i

func _init(position: Vector2i) -> void:
	self.line = position.x
	self.column = position.y
	self.position = position

@abstract func serialise() -> String
