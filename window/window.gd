class_name OSWindow extends Control

@onready var _maximise_button: TextureButton = $TitleBar/ActionButtons/Maximise
@onready var _manager: Node = get_parent()

var _dragging: bool = false
var _drag_offset: Vector2 = Vector2()

enum ResizeMode {
	NONE,
	TOP, BOTTOM, LEFT, RIGHT,
	TOP_LEFT, TOP_RIGHT,
	BOTTOM_LEFT, BOTTOM_RIGHT
}

var _resizing := ResizeMode.NONE
var _resize_start_pos := Vector2.ZERO
var _resize_start_size := Vector2.ZERO
var _resize_start_global_pos := Vector2.ZERO
var _resize_margin := 8

var _restore_rect: Rect2 = Rect2()
var _is_updating_button: bool = false

# Exposed
var maximized: bool = false
@export var rounded_corners: bool = true:
	set(val): _set_setting("rounded_corners", val)
@export var always_on_top: bool = false:
	set(val): _set_setting("always_on_top", val)
@export var borderless: bool = false:
	set(val): _set_setting("borderless", val)
@export var unlisted: bool = false:
	set(val): _set_setting("unlisted", val)
@export var fullscreen: bool = false:
	set(val): _set_setting("fullscreen", val)
@export var movable: bool = true:
	set(val): _set_setting("movable", val)
@export var focusable: bool = true:
	set(val): _set_setting("focusable", val)
@export var resizable: bool = true:
	set(val): _set_setting("resizable", val)

func toggle_size():
	if maximized:
		global_position = _restore_rect.position
		size = _restore_rect.size
		clip_children = CLIP_CHILDREN_ONLY
		maximized = false
	else:
		_restore_rect = Rect2(global_position, size)
		
		var _vp_rect = get_viewport_rect()
		global_position = _vp_rect.position 
		size = _vp_rect.size
		clip_children = CLIP_CHILDREN_DISABLED
		
		maximized = true
	
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	
	if is_node_ready() and get_node_or_null("TitleBar"):
		$TitleBar.set_default_cursor_shape(Control.CURSOR_ARROW)
	
	if _maximise_button:
		_is_updating_button = true
		_maximise_button.button_pressed = maximized
		_is_updating_button = false

func toggle_visibility():
	visible = not visible

# Internal
func _ready() -> void:
	_manager.register_window(self)

func _get_cursor_for_mode(mode: ResizeMode) -> Control.CursorShape:
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
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click and event.pressed:
			toggle_size()
			return
			
		if event.pressed:
			if maximized:
				return
				
			var _global_pos = get_global_mouse_position()
			var _local_pos = _global_pos - global_position 
			
			_resizing = _get_handle_resize(_local_pos)
			
			if _resizing in [ResizeMode.BOTTOM, ResizeMode.BOTTOM_LEFT, ResizeMode.BOTTOM_RIGHT]:
				_resizing = ResizeMode.NONE

			if _resizing != ResizeMode.NONE:
				_dragging = false
				_resize_start_pos = _global_pos
				_resize_start_size = size
				_resize_start_global_pos = global_position
			else:
				_dragging = true
				_drag_offset = _global_pos - global_position
		else:
			_dragging = false
			_resizing = ResizeMode.NONE

	elif event is InputEventMouseMotion:
		if maximized and (_dragging or _resizing != ResizeMode.NONE):
			_dragging = false
			_resizing = ResizeMode.NONE
			return
			
		if _resizing != ResizeMode.NONE:
			_handle_resize(get_global_mouse_position())
		elif _dragging:
			global_position = get_global_mouse_position() - _drag_offset
		else:
			var _global_pos = get_global_mouse_position()
			var _local_pos = _global_pos - global_position
			var _mode = _get_handle_resize(_local_pos)
			
			var _title_bar_node = get_node_or_null("TitleBar") 
			if !_title_bar_node: return
			
			if _mode in [ResizeMode.TOP, ResizeMode.TOP_LEFT, ResizeMode.TOP_RIGHT, ResizeMode.LEFT, ResizeMode.RIGHT]:
				_title_bar_node.set_default_cursor_shape(_get_cursor_for_mode(_mode))
			else:
				_title_bar_node.set_default_cursor_shape(Control.CURSOR_ARROW)


func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			if maximized:
				return
				
			var _potential_resizing = _get_handle_resize(event.position)
			
			if _potential_resizing != ResizeMode.NONE:
				_resizing = _potential_resizing
			
			if _resizing != ResizeMode.NONE:
				_resize_start_pos = get_global_mouse_position()
				_resize_start_size = size
				_resize_start_global_pos = global_position
		else:
			_resizing = ResizeMode.NONE
			set_default_cursor_shape(Control.CURSOR_ARROW)
	
	elif event is InputEventMouseMotion:
		if maximized:
			mouse_default_cursor_shape = Control.CURSOR_ARROW
			return
			
		if _resizing != ResizeMode.NONE:
			_handle_resize(get_global_mouse_position())
		else:
			var _mode = _get_handle_resize(event.position)
			
			if _mode != ResizeMode.NONE:
				mouse_default_cursor_shape = _get_cursor_for_mode(_mode)
			else:
				mouse_default_cursor_shape = Control.CURSOR_ARROW


func _get_handle_resize(pos: Vector2) -> ResizeMode:
	var _left := pos.x < _resize_margin
	var _right := pos.x > size.x - _resize_margin
	var _top := pos.y < _resize_margin
	var _bottom := pos.y > size.y - _resize_margin
	
	if _top and _left: return ResizeMode.TOP_LEFT
	if _top and _right: return ResizeMode.TOP_RIGHT
	if _bottom and _left: return ResizeMode.BOTTOM_LEFT
	if _bottom and _right: return ResizeMode.BOTTOM_RIGHT
	if _top: return ResizeMode.TOP
	if _bottom: return ResizeMode.BOTTOM
	if _left: return ResizeMode.LEFT
	if _right: return ResizeMode.RIGHT
	
	return ResizeMode.NONE

func _handle_resize(mouse_pos: Vector2):
	var _delta = mouse_pos - _resize_start_pos
	var _new_size = _resize_start_size
	
	var _new_pos = _resize_start_global_pos 
	
	match _resizing:
		ResizeMode.RIGHT:
			_new_size.x = _resize_start_size.x + _delta.x
		ResizeMode.BOTTOM:
			_new_size.y = _resize_start_size.y + _delta.y
		ResizeMode.LEFT:
			_new_size.x = _resize_start_size.x - _delta.x
		ResizeMode.TOP:
			_new_size.y = _resize_start_size.y - _delta.y
		ResizeMode.BOTTOM_RIGHT:
			_new_size = _resize_start_size + _delta
		ResizeMode.BOTTOM_LEFT:
			_new_size.x = _resize_start_size.x - _delta.x
			_new_size.y = _resize_start_size.y + _delta.y
		ResizeMode.TOP_RIGHT:
			_new_size.x = _resize_start_size.x + _delta.x
			_new_size.y = _resize_start_size.y - _delta.y
		ResizeMode.TOP_LEFT:
			_new_size = _resize_start_size - _delta
	
	var _clamped_size = Vector2(
		max(_new_size.x, 200),
		max(_new_size.y, 100)
	)
	
	if _resizing in [ResizeMode.LEFT, ResizeMode.TOP_LEFT, ResizeMode.BOTTOM_LEFT]:
		_new_pos.x += (_resize_start_size.x - _clamped_size.x)
	
	if _resizing in [ResizeMode.TOP, ResizeMode.TOP_LEFT, ResizeMode.TOP_RIGHT]:
		_new_pos.y += (_resize_start_size.y - _clamped_size.y)
	
	size = _clamped_size
	global_position = _new_pos

func _on_size_pressed() -> void:
	if _is_updating_button:
		return
		
	toggle_size()

func _set_setting(type: String, value: Variant):
	match type:
		"rounded_corners":
			clip_children = (CLIP_CHILDREN_ONLY if value else CLIP_CHILDREN_DISABLED)
		"resizable":
			_resize_margin = (8 if value else 0)
