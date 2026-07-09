extends Control

class_name UISafePage


func _prepare_safe_ui_root() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS


func _finalize_safe_ui_tree() -> void:
	_apply_safe_mouse_filter(self)


func _apply_safe_mouse_filter(node: Node) -> void:
	if node is Button:
		return

	if node is Control:
		var control := node as Control
		control.mouse_filter = _resolve_mouse_filter(control)

	for child in node.get_children():
		_apply_safe_mouse_filter(child)


func _resolve_mouse_filter(control: Control) -> Control.MouseFilter:
	if control == self:
		return Control.MOUSE_FILTER_PASS

	if control is Button:
		return control.mouse_filter

	if control is ScrollContainer:
		return Control.MOUSE_FILTER_PASS

	if control is Range:
		return Control.MOUSE_FILTER_PASS

	if control is LineEdit or control is TextEdit:
		return Control.MOUSE_FILTER_PASS

	if control is MarginContainer \
	or control is BoxContainer \
	or control is GridContainer \
	or control is PanelContainer \
	or control is ScrollContainer:
		return Control.MOUSE_FILTER_IGNORE

	if control is ColorRect \
	or control is Label \
	or control is RichTextLabel \
	or control is TextureRect \
	or control is NinePatchRect \
	or control is ReferenceRect:
		return Control.MOUSE_FILTER_IGNORE

	return Control.MOUSE_FILTER_IGNORE
