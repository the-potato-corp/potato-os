class_name EvalError

var type: int
var message: String

enum {
	OK,
	VALUE_ERROR,
	TYPE_ERROR,
	NAME_ERROR,
	RUNTIME_ERROR,
	ATTRIBUTE_ERROR,
	INDEX_ERROR,
	KEY_ERROR
}

func _init(type: int, message: String) -> void:
	self.type = type
	self.message = message
