extends Node

func _ready() -> void:
	if OS.has_feature("windows"):
		var drive: String = OS.get_environment("%SystemDrive%")
		print(drive)
		var dir: DirAccess = DirAccess.open(drive)
		print(dir.get_directories())
