var _methods = {}
var _classes = {}

func _init():
	_classes["Widget"] = Widget
	_classes["Text"] = Text

class Widget extends Control:
	var _methods: Dictionary = {}
	
	func _init(): _methods["fill"] = fill; _methods["dock"] = dock; _methods["width"] = width; _methods["height"] = height; _methods["get_size"] = size; _methods["get_position"] = position; _methods["anchor_left"] = set_anchor_left; _methods["anchor_right"] = set_anchor_right; _methods["anchor_top"] = set_anchor_top; _methods["anchor_bottom"] = set_anchor_bottom; _methods["margin_all"] = margin_all; _methods["add"] = add; _methods["remove"] = remove; _methods["get_parent"] = parent; _methods["delete"] = delete
	func fill(): set_anchors_preset(Control.PRESET_FULL_RECT); return self;
	func dock(side: int): set_anchors_preset(Control.PRESET_TOP_WIDE if side == 0 else (Control.PRESET_LEFT_WIDE if side == 1 else (Control.PRESET_BOTTOM_WIDE if side == 2 else Control.PRESET_RIGHT_WIDE))); return self;
	func width(width: int): custom_minimum_size.x = width; return self;
	func height(height: int): custom_minimum_size.y = height; return self;
	func size(): return self.global_size;
	func position(): return self.global_position;
	
	func set_anchor_left(anchor: float): set_anchor(SIDE_LEFT, anchor); return self;
	func set_anchor_right(anchor: float): set_anchor(SIDE_RIGHT, anchor); return self;
	func set_anchor_top(anchor: float): set_anchor(SIDE_TOP, anchor); return self;
	func set_anchor_bottom(anchor: float): set_anchor(SIDE_BOTTOM, anchor); return self;

	func margin_all(margin: float): set_anchor_and_offset(SIDE_TOP, anchor_top, margin); set_anchor_and_offset(SIDE_LEFT, anchor_left, margin); set_anchor_and_offset(SIDE_BOTTOM, anchor_left, margin); set_anchor_and_offset(SIDE_RIGHT, anchor_right, margin); return self;
	
	func add(child: Node): add_child(child); return self
	func remove(child: Node): remove_child(child); return self
	func parent(): return get_parent()
	func delete(): queue_free()

class Text extends Widget:
	var _label: RichTextLabel
	
	func _init(): super(); _methods["text"] = text; _label = RichTextLabel.new(); _label.set_anchors_and_offsets_preset(PRESET_FULL_RECT); add_child(_label);
	func text(text: String): _label.text = text; return self;
