extends Control

var pid: int
var screen_size: Vector2i

# Key states
var ctrl_pressed: bool
var shift_pressed: bool
var alt_pressed: bool
var meta_pressed: bool

# nodes
@export var start_button: TextureButton
@export var start_menu: PanelContainer

func _ready() -> void:
	pid = OS.create_process(ProjectSettings.globalize_path("user://InputCapture.exe"), [OS.get_process_id()])
	screen_size = DisplayServer.screen_get_size()
	start_menu.position.y = screen_size.y
	start_menu.set_meta("target_y", screen_size.y)

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		OS.kill(pid)

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		match event.keycode:
			KEY_CTRL:
				ctrl_pressed = event.pressed
			KEY_SHIFT:
				shift_pressed = event.pressed
			KEY_ALT:
				alt_pressed = event.pressed
			KEY_META:
				meta_pressed = event.pressed
		
		if not event.pressed and event.keycode == KEY_META and not ctrl_pressed and not shift_pressed and not alt_pressed:
			start_button.button_pressed = not start_button.button_pressed
		
		if meta_pressed and event.keycode == KEY_ESCAPE:
			OS.kill(pid)
			get_tree().quit()

func _on_start_toggled(state: bool) -> void:
	var tween: Tween
	if start_menu.has_meta("tween"):
		var old_tween: Tween = start_menu.get_meta("tween")
		if old_tween and old_tween.is_valid():
			old_tween.kill()
			start_menu.position.y = start_menu.get_meta("target_y")
	
	var target_y: int = screen_size.y - int(start_menu.size.y) if state else screen_size.y
	start_menu.set_meta("tween_target", target_y)
	
	tween = start_menu.create_tween()
	start_menu.set_meta("tween", tween)
	
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(start_menu, "position:y", target_y, 0.2)
