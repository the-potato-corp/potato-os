extends Node

func _ready() -> void:
	var dir: DirAccess = DirAccess.open("user://")
	if "potatofs" in dir.get_directories():
		print("Installed!")
	else:
		pass
