extends Control

func _ready() -> void:
	var starch := StarchInstance.new("user://potatofs/system/bin/startup.starch")
	starch.run()
