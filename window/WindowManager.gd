extends Node

var windows: Dictionary = {}
var _next_handle: int = 1
var active_window: OSWindow = null

func register_window(window: OSWindow) -> int:
	var handle = _next_handle
	_next_handle += 1
	windows[handle] = window
	window.activated.connect(_on_window_activated.bind(window))
	_activate_window(window)
	return handle

func unregister_window(handle: int):
	if active_window == windows.get(handle):
		active_window = null
		_find_next_active()
	windows.erase(handle)

func _activate_window(window: OSWindow):
	if active_window == window:
		return
	
	if active_window:
		active_window.emit_signal("focus_lost")
	
	active_window = window
	active_window.emit_signal("focused")
	
	# Z-order
	active_window.get_parent().move_child.call_deferred(active_window, -1)

func _on_window_activated(window: OSWindow):
	_activate_window(window)

func _find_next_active():
	for handle in windows:
		var window = windows[handle]
		if is_instance_valid(window) and window.visible:
			_activate_window(window)
			return
