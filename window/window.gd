extends Control

var dragging: bool = false
var drag_offset: Vector2 = Vector2()

enum ResizeMode {
	NONE,
	TOP, BOTTOM, LEFT, RIGHT,
	TOP_LEFT, TOP_RIGHT,
	BOTTOM_LEFT, BOTTOM_RIGHT
}

var resizing := ResizeMode.NONE
var resize_start_pos := Vector2.ZERO
var resize_start_size := Vector2.ZERO
var resize_start_global_pos := Vector2.ZERO
var resize_margin := 8

# Utility to convert ResizeMode to CursorShape
func get_cursor_for_mode(mode: ResizeMode) -> Control.CursorShape:
	match mode:
		ResizeMode.LEFT, ResizeMode.RIGHT:
			return Control.CURSOR_HSIZE
		ResizeMode.TOP, ResizeMode.BOTTOM:
			return Control.CURSOR_VSIZE
		ResizeMode.TOP_LEFT, ResizeMode.BOTTOM_RIGHT:
			return Control.CURSOR_FDIAGSIZE
		ResizeMode.TOP_RIGHT, ResizeMode.BOTTOM_LEFT:
			return Control.CURSOR_BDIAGSIZE
		_:
			return Control.CURSOR_ARROW


func _on_title_bar_input(event: InputEvent) -> void:
	# NOTE: When handling input on a child node (like the Title Bar), 
	# the cursor shape should ideally be set on that node. 
	# Since we don't have a reference to the Title Bar node here, 
	# we will adjust the cursor shape of the main Control temporarily 
	# or rely on the global input handling if possible.

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var global_pos = get_global_mouse_position()
			var local_pos = global_pos - global_position 
			
			# 1. Check for Resize Mode (TOP, TOP_LEFT, TOP_RIGHT, LEFT, RIGHT)
			resizing = get_resize_mode(local_pos)
			
			# Filter out BOTTOM modes (as Title Bar shouldn't handle them)
			if resizing in [ResizeMode.BOTTOM, ResizeMode.BOTTOM_LEFT, ResizeMode.BOTTOM_RIGHT]:
				resizing = ResizeMode.NONE

			if resizing != ResizeMode.NONE:
				# Start Resizing
				dragging = false
				resize_start_pos = global_pos
				resize_start_size = size
				resize_start_global_pos = global_position
			else:
				# Start Dragging
				dragging = true
				drag_offset = global_pos - global_position
		else:
			# Button Released
			dragging = false
			resizing = ResizeMode.NONE

	elif event is InputEventMouseMotion:
		if resizing != ResizeMode.NONE:
			handle_resize(get_global_mouse_position())
		elif dragging:
			# Continue Dragging
			global_position = get_global_mouse_position() - drag_offset
		else:
			# Update cursor hover on the title bar area
			var global_pos = get_global_mouse_position()
			var local_pos = global_pos - global_position
			var mode = get_resize_mode(local_pos)
			
			# If the mouse is hovering over a resize handle that is active in the title bar area,
			# set the cursor shape on the parent Control.
			if mode in [ResizeMode.TOP, ResizeMode.TOP_LEFT, ResizeMode.TOP_RIGHT, ResizeMode.LEFT, ResizeMode.RIGHT]:
				# Set the cursor shape for the parent Control while the Title Bar is active
				# We must temporarily override the default cursor shape of the Title Bar.
				$TitleBar.set_default_cursor_shape(get_cursor_for_mode(mode))
			else:
				# If hovering over the central drag area of the title bar
				$TitleBar.set_default_cursor_shape(Control.CURSOR_ARROW)
			
			# Note: If this function is truly handling *only* the Title Bar's input,
			# this input event should be consumed (`accept_event()`) to prevent `_gui_input` from running.
			# Since the goal is smooth operation, we assume the title bar input stops propagating 
			# when a drag/resize starts.


func _gui_input(event: InputEvent):
	# If input is consumed by the title bar, this function won't run.
	# We use this primarily for resizing handles not covered by the title bar 
	# (i.e., the bottom margin and margin sides not near the top).

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var potential_resizing = get_resize_mode(event.position)
			
			# Only handle resize modes that the Title Bar doesn't monopolize
			if potential_resizing in [ResizeMode.BOTTOM, ResizeMode.LEFT, ResizeMode.RIGHT, ResizeMode.BOTTOM_LEFT, ResizeMode.BOTTOM_RIGHT]:
				resizing = potential_resizing
			
			if resizing != ResizeMode.NONE:
				resize_start_pos = get_global_mouse_position()
				resize_start_size = size
				resize_start_global_pos = global_position
		else:
			resizing = ResizeMode.NONE
			
			# Reset global cursor shape if mouse is released within the main window control area
			set_default_cursor_shape(Control.CURSOR_ARROW)
	
	elif event is InputEventMouseMotion:
		if resizing != ResizeMode.NONE:
			handle_resize(get_global_mouse_position())
		else:
			# Update cursor based on hover position for non-title bar areas
			var mode = get_resize_mode(event.position)
			
			# Prevent setting cursor if the Title Bar should handle it (i.e., TOP modes)
			# If the Title Bar is truly capturing input, the cursor set in _on_title_bar_input 
			# would prevail when the mouse is over the Title Bar area.
			
			if mode != ResizeMode.NONE:
				# Update the parent Control's cursor shape
				mouse_default_cursor_shape = get_cursor_for_mode(mode)
			else:
				mouse_default_cursor_shape = Control.CURSOR_ARROW


func get_resize_mode(pos: Vector2) -> ResizeMode:
	var left := pos.x < resize_margin
	var right := pos.x > size.x - resize_margin
	var top := pos.y < resize_margin
	var bottom := pos.y > size.y - resize_margin
	
	if top and left: return ResizeMode.TOP_LEFT
	if top and right: return ResizeMode.TOP_RIGHT
	if bottom and left: return ResizeMode.BOTTOM_LEFT
	if bottom and right: return ResizeMode.BOTTOM_RIGHT
	if top: return ResizeMode.TOP
	if bottom: return ResizeMode.BOTTOM
	if left: return ResizeMode.LEFT
	if right: return ResizeMode.RIGHT
	
	return ResizeMode.NONE

func handle_resize(mouse_pos: Vector2):
	var delta = mouse_pos - resize_start_pos
	var new_size = resize_start_size
	
	var new_pos = resize_start_global_pos 
	
	# Calculate new size first
	match resizing:
		ResizeMode.RIGHT:
			new_size.x = resize_start_size.x + delta.x
		ResizeMode.BOTTOM:
			new_size.y = resize_start_size.y + delta.y
		ResizeMode.LEFT:
			new_size.x = resize_start_size.x - delta.x
		ResizeMode.TOP:
			new_size.y = resize_start_size.y - delta.y
		ResizeMode.BOTTOM_RIGHT:
			new_size = resize_start_size + delta
		ResizeMode.BOTTOM_LEFT:
			new_size.x = resize_start_size.x - delta.x
			new_size.y = resize_start_size.y + delta.y
		ResizeMode.TOP_RIGHT:
			new_size.x = resize_start_size.x + delta.x
			new_size.y = resize_start_size.y - delta.y
		ResizeMode.TOP_LEFT:
			new_size = resize_start_size - delta
	
	# Clamp size to minimum
	var clamped_size = Vector2(
		max(new_size.x, 200),
		max(new_size.y, 100)
	)
	
	# Adjust position based on size change (Compensation)
	
	# Compensation for Leftward Movement (X-axis)
	if resizing in [ResizeMode.LEFT, ResizeMode.TOP_LEFT, ResizeMode.BOTTOM_LEFT]:
		new_pos.x += (resize_start_size.x - clamped_size.x)
	
	# Compensation for Upward Movement (Y-axis)
	if resizing in [ResizeMode.TOP, ResizeMode.TOP_LEFT, ResizeMode.TOP_RIGHT]:
		new_pos.y += (resize_start_size.y - clamped_size.y)
	
	size = clamped_size
	global_position = new_pos
