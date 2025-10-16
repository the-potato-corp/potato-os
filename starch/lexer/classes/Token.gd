class_name Token

var type: String
var value: String
var line: int
var column: int

func _init(_type: String, _value: String, _line: int, _column: int) -> void:
	type = _type
	value = _value
	line = _line
	column = _column

func get_data() -> Array:
	return [value, line, column]

func get_position() -> Vector2i:
	return Vector2i(line, column)
