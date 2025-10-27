extends Control

func _ready() -> void:
	var starch := StarchRunner.new("user://potatofs/system/bin/startup.starch")
	starch.run()
