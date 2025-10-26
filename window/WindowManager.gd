extends Node

var windows: Dictionary = {}
var _next_handle: int = 1
var focused_window: OSWindow = null

func register_window(window: OSWindow) -> int:
	var handle = _next_handle
	_next_handle += 1
	windows[handle] = window
	window.activated.connect(_on_window_activated.bind(window))
	_set_focus(window)
	return handle

func get_window_by_handle(handle: int) -> OSWindow:
	return windows.get(handle, null)

func unregister_window(handle: int):
	if focused_window == windows.get(handle):
		focused_window = null
		_find_next_focus()
	
	windows.erase(handle)

func _set_focus(window: OSWindow):
	if focused_window == window:
		return
		
	if focused_window:
		focused_window.emit_signal("focus_lost")
		
	focused_window = window
	
	focused_window.grab_focus()
	focused_window.emit_signal("focused")
	
	focused_window.get_parent().move_child(focused_window, -1) 

func _on_window_activated(window: OSWindow):
	_set_focus(window)

func _find_next_focus():
	for handle in windows:
		var window = windows[handle]
		if is_instance_valid(window) and window.visible:
			_set_focus(window)
			return
