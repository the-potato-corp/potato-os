class_name OSWindow extends Panel

@onready var _maximise_button: TextureButton
var _handle: int

var _dragging: bool = false
var _drag_offset: Vector2 = Vector2()
var _title_bar: Control
var _content: Control

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

var _paths: Dictionary = {
	"icon": "/system/assets/icon.svg",
	"minimise": "/system/assets/minimise.svg",
	"maximise": "/system/assets/maximise.svg",
	"restore": "/system/assets/restore.svg",
	"close": "/system/assets/close.svg"
}

signal activated
signal focused
signal focus_lost

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
		
		if _maximise_button:
			_maximise_button.texture_normal = _load("maximise")
			
	else:
		_restore_rect = Rect2(global_position, size)
		
		var _vp_rect = get_viewport_rect()
		global_position = _vp_rect.position 
		size = _vp_rect.size
		clip_children = CLIP_CHILDREN_DISABLED
		
		maximized = true
		
		if _maximise_button:
			_maximise_button.texture_normal = _load("restore")
			
	
	mouse_default_cursor_shape = CURSOR_ARROW
	
	_title_bar.set_default_cursor_shape(CURSOR_ARROW)
	
	if _maximise_button:
		_is_updating_button = true
		_maximise_button.button_pressed = maximized
		_is_updating_button = false

func toggle_visibility():
	visible = not visible

func get_content():
	return _content

func add_content(child):
	print("ADDING CONTENT (FROM ENGIME)")
	_content.add_child(child)
	print(child)
	print(_content.get_children())

func _close():
	WindowManager.unregister_window(_handle)
	queue_free()

# Internal
func _load(path: String) -> Resource:
	return ImageTexture.create_from_image(Image.load_from_file("user://potatofs".path_join(_paths[path])))

func _init() -> void:
	# self setup
	mouse_filter = MOUSE_FILTER_PASS
	focus_mode = FOCUS_ALL 
	var panel := StyleBoxFlat.new() # this is used only as a mask
	panel.set_corner_radius_all(8)
	add_theme_stylebox_override("panel", panel)
	clip_children = CLIP_CHILDREN_ONLY
	
	# Title bar
	var title_bar := PanelContainer.new()
	title_bar.custom_minimum_size.y = 32
	title_bar.set_anchors_preset(PRESET_TOP_WIDE)
	panel = StyleBoxFlat.new()
	panel.bg_color = Color("#202020")
	panel.set_content_margin_all(3)
	panel.content_margin_left = 4
	title_bar.add_theme_stylebox_override("panel", panel)
	title_bar.gui_input.connect(_on_title_bar_input)
	add_child(title_bar)
	_title_bar = title_bar
	
	# info
	var info := HBoxContainer.new()
	title_bar.add_child(info)
	var icon := TextureRect.new()
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.texture = _load("icon")
	info.add_child(icon)
	var title := Label.new()
	title.text = "Untitled Window"
	info.add_child(title)
	
	# action buttons
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_END
	title_bar.add_child(buttons)
	var minimise := TextureButton.new()
	minimise.texture_normal = _load("minimise")
	minimise.pressed.connect(toggle_visibility)
	buttons.add_child(minimise)
	var maximise := TextureButton.new()
	maximise.texture_normal = _load("maximise")
	maximise.pressed.connect(_on_size_pressed)
	buttons.add_child(maximise)
	var close := TextureButton.new()
	close.texture_normal = _load("close")
	close.pressed.connect(_close)
	buttons.add_child(close)
	
	# content
	var content := Control.new()
	content.set_anchor(SIDE_RIGHT, 1.0)
	content.set_anchor(SIDE_BOTTOM, 1.0)
	content.set_anchor_and_offset(SIDE_TOP, 0.0, 32.0)
	content.mouse_filter = Control.MOUSE_FILTER_STOP
	content.focus_mode = Control.FOCUS_ALL
	add_child(content)
	_maximise_button = maximise
	_content = content
	
	# These are needed to stop the GUI inputs for content going to the node instead of the resize handles 
	var blockers := ColorRect.new()
	blockers.set_anchors_and_offsets_preset(PRESET_FULL_RECT)
	blockers.set_anchor_and_offset(SIDE_TOP, 0.0, 32.0)
	blockers.mouse_filter = MOUSE_FILTER_IGNORE
	add_child(blockers)
	
	var left := ReferenceRect.new()
	left.set_anchor(SIDE_BOTTOM, 1.0)
	left.set_anchor_and_offset(SIDE_RIGHT, 0.0, 8.0)
	blockers.add_child(left)
	#left.editor_only = false
	left.mouse_filter = MOUSE_FILTER_PASS
	left.gui_input.connect(_gui_input)
	var right := ReferenceRect.new()
	right.set_anchor(SIDE_BOTTOM, 1.0)
	right.set_anchor(SIDE_RIGHT, 1.0)
	right.set_anchor_and_offset(SIDE_LEFT, 1.0, -8.0)
	blockers.add_child(right)
	#right.editor_only = false
	right.mouse_filter = MOUSE_FILTER_PASS
	right.gui_input.connect(_gui_input)
	var bottom := ReferenceRect.new()
	bottom.set_anchors_preset(PRESET_BOTTOM_WIDE)
	bottom.set_anchor_and_offset(SIDE_TOP, 1.0, -8)
	blockers.add_child(bottom)
	#bottom.editor_only = false
	bottom.mouse_filter = MOUSE_FILTER_PASS
	bottom.gui_input.connect(_gui_input)
	left.z_index = 1000
	right.z_index = 1000
	bottom.z_index = 1000
	content.z_index = 1

func _ready() -> void:
	_handle = WindowManager.register_window(self)
	focused.connect(_on_window_focused)

func _on_window_focused() -> void:
	if _content:
		_content.grab_focus()

func _on_content_input(event: InputEvent) -> void:
	if WindowManager.focused_window != self:
		return
	
	if event is InputEventKey:
		_propagate_input_to_children(event)
	elif event is InputEventMouseButton:
		if event.pressed:
			emit_signal("activated")
		_propagate_input_to_children(event)
	elif event is InputEventMouseMotion:
		_propagate_input_to_children(event)

func _propagate_input_to_children(event: InputEvent) -> void:
	for child in _content.get_children():
		if child.has_method("_gui_input"):
			child._gui_input(event)

func _get_cursor_for_mode(mode: ResizeMode) -> CursorShape:
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
			emit_signal("activated")
			toggle_size()
			return
			
		if event.pressed:
			emit_signal("activated")
			if maximized:
				return
				
			var _global_pos = get_global_mouse_position()
			var _local_pos = _global_pos - global_position 
			
			_resizing = _get_handle_resize(_local_pos)

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
			# Check resize handles relative to the WINDOW, not title bar
			var _local_pos = get_global_mouse_position() - global_position
			var _mode = _get_handle_resize(_local_pos)
			
			# Set cursor for top edges only (title bar can handle these)
			if _mode in [ResizeMode.TOP, ResizeMode.TOP_LEFT, ResizeMode.TOP_RIGHT]:
				_title_bar.set_default_cursor_shape(_get_cursor_for_mode(_mode))
			else:
				set_default_cursor_shape(CURSOR_ARROW)
				_title_bar.set_default_cursor_shape(CURSOR_ARROW)

func _gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			emit_signal("activated")
			if maximized:
				return
				
			var _potential_resizing = _get_handle_resize(get_local_mouse_position())
			
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
			var _mode = _get_handle_resize(get_local_mouse_position())
			
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
