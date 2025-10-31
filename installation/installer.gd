extends Node

@export var main_scene: PackedScene
var base_url: String = "http://localhost:5500/" if OS.has_feature("editor") else "http://potato-os.github.io/" # dev
var stream: String = "latest"
var version: String = "v0.0.0"
var update: bool = false
var logs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://installation/logs.json"))

func push_text(text: String) -> void:
	%Output.text += text + "\n"

func _ready() -> void:
	%Image.texture = ImageTexture.create_from_image(Image.load_from_file("user://potatofs/system/assets/icon.svg"))
	var font = FontFile.new()
	font.load_dynamic_font("user://potatofs/system/assets/font.ttf")
	%Logo.add_theme_font_override("font", font)
	
	if FileAccess.file_exists("user://version"):
		push_text("Finding version...")
		version = FileAccess.get_file_as_string("user://version")
	else:
		push_text("Saving version...")
		FileAccess.open("user://version", FileAccess.WRITE).store_string(version)
	
	var dir: DirAccess = DirAccess.open("user://")
	if "potatofs" not in dir.get_directories():
		push_text("Initialising PotatoFS...")
		dir.make_dir("potatofs")
	
	if true: # internet rn :)
		var new_version: String = await get_version()
		if semver_greater(new_version, version):
			update = true
			push_text("Update available!")
		
		# Check hashes
		var data: Dictionary = await get_data()
		var files: Dictionary = data["files"]
		for name in files.keys():
			var path: String = "user://potatofs" + name
			var file: Dictionary = files[name]
			var url: String = base_url.path_join(version + file["url"])
			
			if not FileAccess.file_exists(path):
				await download_file(url, path)
				push_text("Downloaded file: " + name)
	
	if false: # in a rush rn
		for text in logs["log_sequence"]:
			push_text(text["message"])
			await get_tree().create_timer(randf_range(0.01, 0.2)).timeout
		
		await get_tree().create_timer(0.8).timeout
		push_text("\nWelcome, user.")
		await get_tree().create_timer(2).timeout
	
	get_tree().change_scene_to_packed(main_scene)

func get_data() -> Dictionary:
	push_text("Getting PotatoFS data...")
	var data: Array = await make_request(base_url.path_join(version + "/data.json"))
	if not data or not is_2xx(data[1]):
		push_text("Failed to get FS data.")
		return {}
	
	var body: String = data[3].get_string_from_utf8()
	var fs: Variant = JSON.parse_string(body)
	if not fs:
		push_text("Invalid FS data.")
		return {}
		
	return fs # just hope it's a dictionary. just pray.

func get_version() -> String:
	push_text("Getting update data...")
	var data: Array = await make_request(base_url.path_join("channels.cfg"))
	if not data or not is_2xx(data[1]):
		push_text("Failed to get channel index.")
		return ""
	
	var body: PackedByteArray = data[3]
	var channels: ConfigFile = ConfigFile.new()
	var error: Error = channels.parse(body.get_string_from_utf8())
	if error != OK:
		push_text("Invalid channel index.")
		return ""
	
	return channels.get_value("channels", stream, "")

func hash_file(path: String, method: String) -> String:
	match method:
		"sha256":
			return FileAccess.get_sha256(path)
		"md5":
			return FileAccess.get_md5(path)
		_:
			push_text("Unsupported hashing method: " + method)
			return ""

func semver_greater(a: String, b: String) -> bool:
	var a_value: Array = parse_semver(a)
	var b_value: Array = parse_semver(b)
	if a_value[0] > b_value[0]:
		return true
	
	if a_value[0] < b_value[0]:
		return false
	
	if a_value[1] > b_value[1]:
		return true
	if a_value[1] < b_value[1]:
		return false
		
	if a_value[2] > b_value[2]:
		return true
	
	return false

func parse_semver(version: String) -> Array:
	var out: Array = []
	for v in version.split("."):
		out.append(int(v))
	return out

func is_2xx(code: int) -> bool:
	return code < 300 and code >= 200

func download_file(url: String, path: String) -> bool:
	DirAccess.make_dir_recursive_absolute(path.rsplit("/", true, 1)[0])
	push_text("Downloading " + path + "...")
	var result: Array = await make_request(url)
	if is_2xx(result[1]):
		var access: FileAccess = FileAccess.open(path, FileAccess.WRITE)
		var success: bool = access.store_buffer(result[3])
		access.close() # Manually flush ig
		return success
	return false

func make_request(url: String) -> Array:
	var request: HTTPRequest = HTTPRequest.new()
	add_child(request)
	var error: Error = request.request(url)
	if error != OK:
		return []
	var data: Array = await request.request_completed
	request.queue_free()
	return data
