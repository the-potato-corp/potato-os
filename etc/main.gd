extends Control

var startup: String = "user://potatofs/system/bin/startup.starch"

func _ready() -> void:
	WindowManager._root = self
	var file = FileAccess.open(startup, FileAccess.READ)
	var content = file.get_as_text()
	
	# DEBUG: Print raw bytes of first 100 chars
	print("File: ", startup)
	print("Length: ", content.length())
	print("First 100 chars: ", content.substr(0, 100))
	print("Byte array: ", content.substr(0, 100).to_utf8_buffer())
	var starch := StarchRunner.new(ProjectSettings.globalize_path(startup))
	starch.run()
