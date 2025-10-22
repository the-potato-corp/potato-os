extends Node

var windows: Dictionary = {}
var _next_handle: int = 1

func register_window(window: OSWindow) -> int:
	var handle = _next_handle
	_next_handle += 1
	windows[handle] = window
	return handle

func get_window_by_handle(handle: int) -> OSWindow:
	return windows.get(handle, null)

func unregister_window(handle: int):
	windows.erase(handle)
