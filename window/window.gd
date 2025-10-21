extends Control

@onready var maximise_button: TextureButton = $TitleBar/ActionButtons/Maximise

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

var maximized: bool = false
var restore_rect: Rect2 = Rect2()

var is_updating_button: bool = false


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


func toggle_size():
	if maximized:
		global_position = restore_rect.position
		size = restore_rect.size
		maximized = false
	else:
		restore_rect = Rect2(global_position, size)
		
		var vp_rect = get_viewport_rect()
		global_position = vp_rect.position 
		size = vp_rect.size
		
		maximized = true
	
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	
	if is_node_ready() and get_node_or_null("TitleBar"):
		$TitleBar.set_default_cursor_shape(Control.CURSOR_ARROW)
	
	if maximise_button:
		is_updating_button = true
		maximise_button.button_pressed = maximized
		is_updating_button = false


func _on_title_bar_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click and event.pressed:
			toggle_size()
			return
			
		if event.pressed:
			if maximized:
				return
				
			var global_pos = get_global_mouse_position()
			var local_pos = global_pos - global_position 
			
			resizing = get_resize_mode(local_pos)
			
			if resizing in [ResizeMode.BOTTOM, ResizeMode.BOTTOM_LEFT, ResizeMode.BOTTOM_RIGHT]:
				resizing = ResizeMode.NONE

			if resizing != ResizeMode.NONE:
				dragging = false
				resize_start_pos = global_pos
				resize_start_size = size
				resize_start_global_pos = global_position
			else:
				dragging = true
				drag_offset = global_pos - global_position
		else:
			dragging = false
			resizing = ResizeMode.NONE

	elif event is InputEventMouseMotion:
		if maximized and (dragging or resizing != ResizeMode.NONE):
			dragging = false
			resizing = ResizeMode.NONE
			return
			
		if resizing != ResizeMode.NONE:
			handle_resize(get_global_mouse_position())
		elif dragging:
			global_position = get_global_mouse_position() - drag_offset
		else:
			var global_pos = get_global_mouse_position()
			var local_pos = global_pos - global_position
			var mode = get_resize_mode(local_pos)
			
			var title_bar_node = get_node_or_null("TitleBar") 
			if !title_bar_node: return
			
			if mode in [ResizeMode.TOP, ResizeMode.TOP_LEFT, ResizeMode.TOP_RIGHT, ResizeMode.LEFT, ResizeMode.RIGHT]:
				title_bar_node.set_default_cursor_shape(get_cursor_for_mode(mode))
			else:
				title_bar_node.set_default_cursor_shape(Control.CURSOR_ARROW)


func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if maximized:
				return
				
			var potential_resizing = get_resize_mode(event.position)
			
			if potential_resizing != ResizeMode.NONE:
				resizing = potential_resizing
			
			if resizing != ResizeMode.NONE:
				resize_start_pos = get_global_mouse_position()
				resize_start_size = size
				resize_start_global_pos = global_position
		else:
			resizing = ResizeMode.NONE
			set_default_cursor_shape(Control.CURSOR_ARROW)
	
	elif event is InputEventMouseMotion:
		if maximized:
			mouse_default_cursor_shape = Control.CURSOR_ARROW
			return
			
		if resizing != ResizeMode.NONE:
			handle_resize(get_global_mouse_position())
		else:
			var mode = get_resize_mode(event.position)
			
			if mode != ResizeMode.NONE:
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
	
	var clamped_size = Vector2(
		max(new_size.x, 200),
		max(new_size.y, 100)
	)
	
	if resizing in [ResizeMode.LEFT, ResizeMode.TOP_LEFT, ResizeMode.BOTTOM_LEFT]:
		new_pos.x += (resize_start_size.x - clamped_size.x)
	
	if resizing in [ResizeMode.TOP, ResizeMode.TOP_LEFT, ResizeMode.TOP_RIGHT]:
		new_pos.y += (resize_start_size.y - clamped_size.y)
	
	size = clamped_size
	global_position = new_pos

func _on_size_pressed() -> void:
	if is_updating_button:
		return
		
	toggle_size()
