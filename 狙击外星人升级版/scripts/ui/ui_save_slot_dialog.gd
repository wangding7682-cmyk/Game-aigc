extends Control


var dialog_mode: String = "load"
var on_slot_selected: Callable = Callable()
var on_cancel: Callable = Callable()

var title_label: Label
var slots_vbox: VBoxContainer
var cancel_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build_ui()


func show_dialog(mode: String, on_selected: Callable, on_cancel_callback: Callable) -> void:
	dialog_mode = mode
	on_slot_selected = on_selected
	on_cancel = on_cancel_callback
	title_label.text = "读取存档" if mode == "load" else "保存存档"
	_refresh_slots()
	visible = true


func _hide() -> void:
	visible = false


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color(0.02, 0.04, 0.06, 0.86)
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	var dialog_panel := PanelContainer.new()
	dialog_panel.set_anchors_preset(Control.PRESET_CENTER)
	dialog_panel.custom_minimum_size = Vector2(420, 520)
	dialog_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	dialog_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_apply_dialog_panel_style(dialog_panel)
	add_child(dialog_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 20)
	dialog_panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 14)
	margin.add_child(vbox)

	title_label = Label.new()
	title_label.text = "读取存档"
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_constant_override("outline_size", 6)
	title_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.94))
	vbox.add_child(title_label)

	var intro := Label.new()
	intro.text = "选择一个存档档位进行操作。"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.modulate = Color(0.84, 0.90, 0.98)
	intro.add_theme_font_size_override("font_size", 14)
	vbox.add_child(intro)

	slots_vbox = VBoxContainer.new()
	slots_vbox.add_theme_constant_override("separation", 10)
	slots_vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(slots_vbox)

	cancel_button = Button.new()
	cancel_button.text = "取消"
	cancel_button.custom_minimum_size = Vector2(0, 48)
	cancel_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cancel_button.pressed.connect(func() -> void:
		if on_cancel != null:
			on_cancel.call()
		_hide()
	)
	_apply_action_button_style(cancel_button, "secondary")
	vbox.add_child(cancel_button)


func _refresh_slots() -> void:
	for child in slots_vbox.get_children():
		child.queue_free()

	var slots_info := CoreSaveService.get_all_slots_info()
	for slot_info in slots_info:
		var slot_button := _make_slot_button(slot_info)
		slots_vbox.add_child(slot_button)


func _make_slot_button(slot_info: Dictionary) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 88)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	var exists: bool = bool(slot_info.get("exists", false))
	var slot_index: int = int(slot_info.get("slot_index", 0))
	var saved_at: String = str(slot_info.get("saved_at", ""))
	var level_id: int = int(slot_info.get("level_id", 0))
	var player_gold: int = int(slot_info.get("player_gold", 0))

	if exists:
		var level_config: PveLevelConfig = CoreGameState.get_level_config(level_id)
		var level_name := str(level_config.display_name)
		button.text = "存档位 %d\n关卡 %d《%s》 · 金币 %d\n%s" % [
			slot_index,
			level_id,
			level_name,
			player_gold,
			saved_at,
		]
		_apply_slot_button_style(button, true)
	else:
		button.text = "存档位 %d\n空档位" % slot_index
		_apply_slot_button_style(button, false)

	button.pressed.connect(func() -> void:
		if not on_slot_selected.is_null():
			on_slot_selected.call(slot_index)
		_hide()
	)

	return button


func _apply_dialog_panel_style(panel: PanelContainer) -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 20
	style.corner_radius_top_right = 20
	style.corner_radius_bottom_left = 20
	style.corner_radius_bottom_right = 20
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.shadow_size = 12
	style.shadow_color = Color(0.01, 0.02, 0.04, 0.42)
	style.bg_color = Color(0.08, 0.12, 0.18, 0.98)
	style.border_color = Color(0.56, 0.74, 1.0, 0.46)
	panel.add_theme_stylebox_override("panel", style)


func _apply_slot_button_style(button: Button, has_save: bool) -> void:
	var normal := StyleBoxFlat.new()
	var hover := StyleBoxFlat.new()
	var pressed := StyleBoxFlat.new()
	var focus := StyleBoxFlat.new()

	if has_save:
		normal.bg_color = Color(0.12, 0.20, 0.30, 0.94)
		hover.bg_color = Color(0.18, 0.28, 0.42, 0.98)
		pressed.bg_color = Color(0.10, 0.16, 0.24, 0.98)
		focus.bg_color = Color(0.22, 0.34, 0.50, 1.0)
	else:
		normal.bg_color = Color(0.10, 0.12, 0.16, 0.72)
		hover.bg_color = Color(0.14, 0.18, 0.24, 0.86)
		pressed.bg_color = Color(0.08, 0.10, 0.14, 0.88)
		focus.bg_color = Color(0.16, 0.22, 0.30, 0.92)

	var border_color := Color(0.48, 0.64, 0.84, 0.42)

	for stylebox in [normal, hover, pressed, focus]:
		stylebox.corner_radius_top_left = 16
		stylebox.corner_radius_top_right = 16
		stylebox.corner_radius_bottom_left = 16
		stylebox.corner_radius_bottom_right = 16
		stylebox.content_margin_left = 16
		stylebox.content_margin_right = 16
		stylebox.content_margin_top = 12
		stylebox.content_margin_bottom = 12
		stylebox.border_width_left = 1
		stylebox.border_width_top = 1
		stylebox.border_width_right = 1
		stylebox.border_width_bottom = 1
		stylebox.border_color = border_color
		stylebox.shadow_color = Color(0.01, 0.02, 0.04, 0.18)
		stylebox.shadow_size = 4

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_color_override("font_focus_color", Color(1, 1, 1))
	button.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.07, 0.96))
	button.add_theme_constant_override("outline_size", 3)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_constant_override("line_separation", 3)


func _apply_action_button_style(button: Button, tone: String) -> void:
	var normal := StyleBoxFlat.new()
	var hover := StyleBoxFlat.new()
	var pressed := StyleBoxFlat.new()
	var focus := StyleBoxFlat.new()
	var border_color := Color(0.42, 0.56, 0.72, 0.55)
	var color := Color(0.10, 0.16, 0.23, 0.94)
	var hover_color := Color(0.15, 0.22, 0.31, 0.98)
	var pressed_color := Color(0.08, 0.13, 0.19, 0.98)
	var focus_color := Color(0.18, 0.28, 0.40, 1.0)

	if tone == "danger":
		color = Color(0.28, 0.10, 0.12, 0.92)
		hover_color = Color(0.36, 0.12, 0.15, 0.98)
		pressed_color = Color(0.24, 0.08, 0.10, 0.98)
		focus_color = Color(0.42, 0.14, 0.18, 1.0)
		border_color = Color(1.0, 0.56, 0.58, 0.46)
	elif tone == "positive":
		color = Color(0.10, 0.34, 0.42, 0.96)
		hover_color = Color(0.14, 0.44, 0.54, 1.0)
		pressed_color = Color(0.08, 0.28, 0.36, 1.0)
		focus_color = Color(0.18, 0.52, 0.64, 1.0)
		border_color = Color(0.60, 0.92, 1.0, 0.60)
	elif tone == "secondary":
		color = Color(0.12, 0.20, 0.30, 0.94)
		hover_color = Color(0.16, 0.26, 0.38, 0.98)
		pressed_color = Color(0.10, 0.16, 0.24, 0.98)
		focus_color = Color(0.20, 0.32, 0.46, 1.0)
		border_color = Color(0.64, 0.80, 0.98, 0.44)

	for stylebox in [normal, hover, pressed, focus]:
		stylebox.corner_radius_top_left = 16
		stylebox.corner_radius_top_right = 16
		stylebox.corner_radius_bottom_left = 16
		stylebox.corner_radius_bottom_right = 16
		stylebox.content_margin_left = 14
		stylebox.content_margin_right = 14
		stylebox.content_margin_top = 10
		stylebox.content_margin_bottom = 10
		stylebox.border_width_left = 1
		stylebox.border_width_top = 1
		stylebox.border_width_right = 1
		stylebox.border_width_bottom = 1
		stylebox.border_color = border_color
		stylebox.shadow_color = Color(0.01, 0.02, 0.04, 0.20)
		stylebox.shadow_size = 4

	normal.bg_color = color
	hover.bg_color = hover_color
	pressed.bg_color = pressed_color
	focus.bg_color = focus_color

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_color_override("font_focus_color", Color(1, 1, 1))
	button.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.07, 0.96))
	button.add_theme_constant_override("outline_size", 3)