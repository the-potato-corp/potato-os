extends Node

var pipes: Dictionary
var thread: Thread
var running: bool = true
var event_queue: Array[String] = []
var queue_mutex: Mutex = Mutex.new()

func _ready() -> void:
	pipes = OS.execute_with_pipe(ProjectSettings.globalize_path("user://KeyboardHook.exe"), [])
	thread = Thread.new()
	thread.start(_poll_input)

func _poll_input() -> void:
	var pipe = pipes["stdio"]
	
	while running and pipe.is_open():
		var line: String = pipe.get_line()
		if line != "" and running:
			queue_mutex.lock()
			event_queue.append(line)
			queue_mutex.unlock()

func _process(_delta: float) -> void:
	queue_mutex.lock()
	var events: Array[String] = event_queue.duplicate()
	event_queue.clear()
	queue_mutex.unlock()
	
	for line in events:
		_inject_event(line)

func _inject_event(line: String) -> void:
	var parts: PackedStringArray = line.split(" ")
	if parts.size() < 7:
		return
	
	var event_type: String = parts[0]
	var keycode: int = parts[1].to_int()
	var unicode: int = parts[2].split("=")[1].to_int()
	var shift: bool = parts[3].split("=")[1] == "1"
	var ctrl: bool = parts[4].split("=")[1] == "1"
	var alt: bool = parts[5].split("=")[1] == "1"
	var meta: bool = parts[6].split("=")[1] == "1"
	
	var event: InputEventKey = InputEventKey.new()
	event.keycode = keycode as Key
	event.physical_keycode = keycode as Key
	event.unicode = unicode
	event.pressed = (event_type == "KEY_DOWN")
	event.shift_pressed = shift
	event.ctrl_pressed = ctrl
	event.alt_pressed = alt
	event.meta_pressed = meta
	
	if event.pressed:
		event.echo = _is_key_held(keycode)
	
	Input.parse_input_event(event)
	_update_key_state(keycode, event.pressed)

var _held_keys: Dictionary = {}

func _is_key_held(keycode: int) -> bool:
	return _held_keys.get(keycode, false)

func _update_key_state(keycode: int, pressed: bool) -> void:
	_held_keys[keycode] = pressed

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		running = false
		if thread.is_alive():
			thread.wait_to_finish()
		OS.kill(pipes["pid"])
