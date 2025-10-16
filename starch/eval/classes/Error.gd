class_name EvalError

var type: int
var message: String

enum {
	VALUE_ERROR,
	TYPE_ERROR,
	NAME_ERROR
}

func _init(type: int, message: String) -> void:
	self.type = type
	self.message = message
