extends Control

var startup: String = "user://potatofs/system/bin/startup.starch"

func _ready() -> void:
	WindowManager._root = self
	var starch := StarchRunner.new(ProjectSettings.globalize_path(startup))
	starch.run()
