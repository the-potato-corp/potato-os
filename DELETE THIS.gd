var _methods = {}
var _classes = {}

func _init():
	_classes["Widget"] = Widget

class Widget extends Control:
	func _init(): pass
	func fill(): self.set_anchors_preset(Control.PRESET_FULL_RECT); return self;
	func dock(side: int): self.set_anchors_preset(Control.PRESET_TOP_WIDE if side == 0 else (Control.PRESET_LEFT_WIDE if side == 1 else (Control.PRESET_BOTTOM_WIDE if side == 2 else Control.PRESET_RIGHT_WIDE))); return self;
	func width(width: int): self.custom_minimum_size.x = width; return self;
	func height(height: int): self.custom_minimum_size.y = height; return self;
	func size(): return self.global_size;
	func position(): return self.global_position;
	
	func set_anchor_left(anchor: float): self.set_anchor(SIDE_LEFT, anchor); return self;
	func set_anchor_right(anchor: float): self.set_anchor(SIDE_RIGHT, anchor); return self;
	func set_anchor_top(anchor: float): self.set_anchor(SIDE_TOP, anchor); return self;
	func set_anchor_bottom(anchor: float): self.set_anchor(SIDE_BOTTOM, anchor); return self;

	func margin_all(margin: float): self.set_anchor_and_offset(SIDE_TOP, self.anchor_top, margin); self.set_anchor_and_offset(SIDE_LEFT, self.anchor_left, margin); self.set_anchor_and_offset(SIDE_BOTTOM, self.anchor_left, margin); self.set_anchor_and_offset(SIDE_RIGHT, self.anchor_right, margin); return self;
	
	func add(child): return self
	func remove(child): return self
	func parent(): return get_parent()
