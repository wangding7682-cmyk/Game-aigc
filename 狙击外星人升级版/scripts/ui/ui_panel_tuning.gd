extends "res://scripts/ui/ui_safe_page.gd"

const MENU_KEY_ART := preload("res://assets_mvp_placeholder/ui/menu-key-art.jpg")
const LOADING_SCOPE_ART := preload("res://assets_mvp_placeholder/ui/loading-scope-art.jpg")
const POSITION_STEP := 10.0

var level_id := 1
var level_config: Resource
var selected_index := 0

var header_label: Label
var feedback_label: Label
var list_container: VBoxContainer
var detail_label: Label
var stepper_value_labels: Dictionary = {}
var title_label: Label
var intro_label: Label
var hint_label: Label


func _ready() -> void:
	level_id = CoreGameState.current_level_id
	_prepare_safe_ui_root()
	_build_ui()
	_finalize_safe_ui_tree()
	_load_level(level_id)


func _build_ui() -> void:
	var backdrop := TextureRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.texture = MENU_KEY_ART
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(backdrop)

	var tint := ColorRect.new()
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(0.02, 0.04, 0.06, 0.76)
	add_child(tint)

	var top_glow := ColorRect.new()
	top_glow.anchor_left = 0.0
	top_glow.anchor_top = 0.0
	top_glow.anchor_right = 1.0
	top_glow.anchor_bottom = 0.22
	top_glow.color = Color(0.08, 0.15, 0.24, 0.26)
	add_child(top_glow)

	var root_margin := MarginContainer.new()
	root_margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	root_margin.add_theme_constant_override("margin_left", 28)
	root_margin.add_theme_constant_override("margin_top", 24)
	root_margin.add_theme_constant_override("margin_right", 28)
	root_margin.add_theme_constant_override("margin_bottom", 24)
	add_child(root_margin)

	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 14)
	root_margin.add_child(shell)

	var header_panel := PanelContainer.new()
	_apply_surface_panel_style(header_panel, true)
	shell.add_child(header_panel)

	var header_margin := MarginContainer.new()
	header_margin.add_theme_constant_override("margin_left", 18)
	header_margin.add_theme_constant_override("margin_top", 16)
	header_margin.add_theme_constant_override("margin_right", 18)
	header_margin.add_theme_constant_override("margin_bottom", 16)
	header_panel.add_child(header_margin)

	var header_vbox := VBoxContainer.new()
	header_vbox.add_theme_constant_override("separation", 10)
	header_margin.add_child(header_vbox)

	var eyebrow := Label.new()
	eyebrow.text = "关卡校准终端"
	eyebrow.modulate = Color(0.90, 0.95, 1.0, 0.94)
	eyebrow.add_theme_font_size_override("font_size", 16)
	eyebrow.add_theme_constant_override("outline_size", 5)
	eyebrow.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.92))
	header_vbox.add_child(eyebrow)

	title_label = Label.new()
	title_label.text = "关卡调参面板（内部）"
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_constant_override("outline_size", 7)
	title_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.94))
	header_vbox.add_child(title_label)

	intro_label = Label.new()
	intro_label.text = "直接校准关卡内的出生条目、伪装强度、移动范围、弱点周期与搜索信号。"
	intro_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro_label.modulate = Color(0.84, 0.90, 0.98)
	intro_label.add_theme_font_size_override("font_size", 15)
	intro_label.add_theme_constant_override("line_separation", 4)
	header_vbox.add_child(intro_label)

	hint_label = Label.new()
	hint_label.text = "首屏优先给出切关、保存、条目列表与常用参数；更多参数可在右侧滚动区继续调。"
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.modulate = Color(0.96, 0.80, 0.42)
	hint_label.add_theme_font_size_override("font_size", 14)
	header_vbox.add_child(hint_label)

	var status_panel := PanelContainer.new()
	_apply_surface_panel_style(status_panel, false)
	shell.add_child(status_panel)

	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 16)
	status_margin.add_theme_constant_override("margin_top", 14)
	status_margin.add_theme_constant_override("margin_right", 16)
	status_margin.add_theme_constant_override("margin_bottom", 14)
	status_panel.add_child(status_margin)

	var status_vbox := VBoxContainer.new()
	status_vbox.add_theme_constant_override("separation", 10)
	status_margin.add_child(status_vbox)

	header_label = Label.new()
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	header_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	header_label.modulate = Color(0.78, 0.86, 0.98)
	status_vbox.add_child(header_label)

	feedback_label = Label.new()
	feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	feedback_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	feedback_label.modulate = Color(0.72, 0.98, 0.82)
	status_vbox.add_child(feedback_label)

	var top_actions := GridContainer.new()
	top_actions.columns = 3
	top_actions.add_theme_constant_override("h_separation", 10)
	top_actions.add_theme_constant_override("v_separation", 10)
	status_vbox.add_child(top_actions)

	var prev_button := Button.new()
	prev_button.text = "上一关"
	prev_button.custom_minimum_size = Vector2(0, 44)
	prev_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	prev_button.pressed.connect(func() -> void:
		_load_level(clampi(level_id - 1, 1, CoreGameState.LEVEL_PATHS.size()))
	)
	_apply_action_button_style(prev_button, "secondary")
	top_actions.add_child(prev_button)

	var next_button := Button.new()
	next_button.text = "下一关"
	next_button.custom_minimum_size = Vector2(0, 44)
	next_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	next_button.pressed.connect(func() -> void:
		_load_level(clampi(level_id + 1, 1, CoreGameState.LEVEL_PATHS.size()))
	)
	_apply_action_button_style(next_button, "secondary")
	top_actions.add_child(next_button)

	var save_button := Button.new()
	save_button.text = "保存到关卡配置"
	save_button.custom_minimum_size = Vector2(0, 44)
	save_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_button.pressed.connect(_save_level_config)
	_apply_action_button_style(save_button, "primary")
	top_actions.add_child(save_button)

	var reload_button := Button.new()
	reload_button.text = "重新加载（丢弃未保存）"
	reload_button.custom_minimum_size = Vector2(0, 44)
	reload_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reload_button.pressed.connect(func() -> void:
		_load_level(level_id)
	)
	_apply_action_button_style(reload_button, "secondary")
	top_actions.add_child(reload_button)

	var back_button := Button.new()
	back_button.text = "返回主页"
	back_button.custom_minimum_size = Vector2(0, 44)
	back_button.pressed.connect(func() -> void:
		RouteGuard.request_route("main_menu", "调参面板-返回主页")
	)
	_apply_action_button_style(back_button, "secondary")
	top_actions.add_child(back_button)

	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 14)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(columns)

	var list_panel := PanelContainer.new()
	list_panel.custom_minimum_size = Vector2(340, 0)
	list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_surface_panel_style(list_panel, false)
	columns.add_child(list_panel)

	var list_margin := MarginContainer.new()
	list_margin.add_theme_constant_override("margin_left", 12)
	list_margin.add_theme_constant_override("margin_top", 12)
	list_margin.add_theme_constant_override("margin_right", 12)
	list_margin.add_theme_constant_override("margin_bottom", 12)
	list_panel.add_child(list_margin)

	var list_vbox := VBoxContainer.new()
	list_vbox.add_theme_constant_override("separation", 8)
	list_margin.add_child(list_vbox)

	var list_title := Label.new()
	list_title.text = "条目列表"
	list_title.add_theme_font_size_override("font_size", 20)
	list_vbox.add_child(list_title)

	var list_scroll := ScrollContainer.new()
	list_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	list_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	list_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	list_vbox.add_child(list_scroll)

	list_container = VBoxContainer.new()
	list_container.add_theme_constant_override("separation", 8)
	list_scroll.add_child(list_container)

	var detail_panel := PanelContainer.new()
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_surface_panel_style(detail_panel, false)
	columns.add_child(detail_panel)

	var detail_margin := MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 12)
	detail_margin.add_theme_constant_override("margin_top", 12)
	detail_margin.add_theme_constant_override("margin_right", 12)
	detail_margin.add_theme_constant_override("margin_bottom", 12)
	detail_panel.add_child(detail_margin)

	var detail_scroll := ScrollContainer.new()
	detail_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	detail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	detail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	detail_margin.add_child(detail_scroll)

	var detail_vbox := VBoxContainer.new()
	detail_vbox.add_theme_constant_override("separation", 10)
	detail_scroll.add_child(detail_vbox)

	var detail_title := Label.new()
	detail_title.text = "参数详情"
	detail_title.add_theme_font_size_override("font_size", 22)
	detail_vbox.add_child(detail_title)

	detail_label = Label.new()
	detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail_label.add_theme_font_size_override("font_size", 18)
	detail_vbox.add_child(detail_label)

	_add_entry_controls(detail_vbox)


func _load_level(target_level: int) -> void:
	level_id = clampi(target_level, 1, CoreGameState.LEVEL_PATHS.size())
	feedback_label.text = ""

	var path := CoreGameState.get_level_config_path(level_id)
	level_config = load(path)
	selected_index = 0
	_rebuild_entry_list()
	_refresh_detail()
	header_label.text = "当前关卡：%d | 配置：%s" % [level_id, path]


func _rebuild_entry_list() -> void:
	for child in list_container.get_children():
		child.queue_free()

	if level_config == null:
		return

	var entries: Array = level_config.spawn_entries
	for idx in range(entries.size()):
		var entry = entries[idx]
		var button := Button.new()
		button.text = "#%d %s/%s (%.0f, %.0f)" % [
			idx + 1,
			str(entry.actor_kind),
			str(entry.behavior_type),
			float(entry.position.x),
			float(entry.position.y),
		]
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.custom_minimum_size = Vector2(0, 40)
		button.pressed.connect(func() -> void:
			selected_index = idx
			_refresh_detail()
		)
		list_container.add_child(button)


func _get_selected_entry():
	if level_config == null:
		return null
	var entries: Array = level_config.spawn_entries
	if selected_index < 0 or selected_index >= entries.size():
		return null
	return entries[selected_index]


func _refresh_detail() -> void:
	var entry = _get_selected_entry()
	if entry == null:
		detail_label.text = "未选择条目"
		_refresh_stepper_values(null)
		return

	detail_label.text = "条目 #%d\nkind=%s  behavior=%s\nposition=(%.1f, %.1f)\n伪装强度=%.2f\n移动范围=%.1f  移动速度=%.2f\n弱点周期=%.2f  弱点窗口=%.2f\n可疑等级=%d  信号强度=%.2f\n线索=%s" % [
		selected_index + 1,
		str(entry.actor_kind),
		str(entry.behavior_type),
		float(entry.position.x),
		float(entry.position.y),
		float(entry.disguise_strength),
		float(entry.move_range),
		float(entry.move_speed),
		float(entry.reveal_cycle_sec),
		float(entry.reveal_window_sec),
		int(entry.suspicion_tier),
		float(entry.search_signal_strength),
		"、".join(entry.clue_profile),
	]
	_refresh_stepper_values(entry)


func _add_entry_controls(parent: VBoxContainer) -> void:
	var grid := GridContainer.new()
	# 4 列：参数名 / 减少 / 当前值 / 增加
	# 这样“按钮”和“数值”在视觉上是一眼关联的，不需要抬头看详情块对照。
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	parent.add_child(grid)

	_add_stepper(grid, "位置 X", "pos_x", func(delta: float) -> void:
		var entry = _get_selected_entry()
		if entry == null:
			return
		entry.position.x += delta
		_rebuild_entry_list()
		_refresh_detail()
	, -POSITION_STEP, POSITION_STEP)

	_add_stepper(grid, "位置 Y", "pos_y", func(delta: float) -> void:
		var entry = _get_selected_entry()
		if entry == null:
			return
		entry.position.y += delta
		_rebuild_entry_list()
		_refresh_detail()
	, -POSITION_STEP, POSITION_STEP)

	_add_stepper(grid, "伪装强度", "disguise_strength", func(delta: float) -> void:
		var entry = _get_selected_entry()
		if entry == null:
			return
		entry.disguise_strength = clampf(float(entry.disguise_strength) + delta, 0.0, 1.0)
		_refresh_detail()
	, -0.05, 0.05)

	_add_stepper(grid, "移动范围", "move_range", func(delta: float) -> void:
		var entry = _get_selected_entry()
		if entry == null:
			return
		entry.move_range = maxf(float(entry.move_range) + delta, -1.0)
		_refresh_detail()
	, -5.0, 5.0)

	_add_stepper(grid, "移动速度", "move_speed", func(delta: float) -> void:
		var entry = _get_selected_entry()
		if entry == null:
			return
		entry.move_speed = maxf(float(entry.move_speed) + delta, -1.0)
		_refresh_detail()
	, -0.05, 0.05)

	_add_stepper(grid, "弱点周期", "reveal_cycle_sec", func(delta: float) -> void:
		var entry = _get_selected_entry()
		if entry == null:
			return
		entry.reveal_cycle_sec = maxf(float(entry.reveal_cycle_sec) + delta, -1.0)
		_refresh_detail()
	, -0.1, 0.1)

	_add_stepper(grid, "弱点窗口", "reveal_window_sec", func(delta: float) -> void:
		var entry = _get_selected_entry()
		if entry == null:
			return
		entry.reveal_window_sec = maxf(float(entry.reveal_window_sec) + delta, -1.0)
		_refresh_detail()
	, -0.05, 0.05)

	_add_stepper(grid, "可疑等级", "suspicion_tier", func(delta: float) -> void:
		var entry = _get_selected_entry()
		if entry == null:
			return
		entry.suspicion_tier = clampi(int(entry.suspicion_tier) + int(delta), -1, 3)
		_refresh_detail()
	, -1, 1)

	_add_stepper(grid, "信号强度", "search_signal_strength", func(delta: float) -> void:
		var entry = _get_selected_entry()
		if entry == null:
			return
		entry.search_signal_strength = maxf(float(entry.search_signal_strength) + delta, -1.0)
		_refresh_detail()
	, -0.05, 0.05)

	var preset_button := Button.new()
	preset_button.text = "应用默认线索预设"
	preset_button.custom_minimum_size = Vector2(0, 46)
	_apply_action_button_style(preset_button, "secondary")
	preset_button.pressed.connect(_apply_default_clue_preset)
	parent.add_child(preset_button)


func _add_stepper(grid: GridContainer, label: String, value_key: String, apply_delta: Callable, minus_delta: float, plus_delta: float) -> void:
	var title := Label.new()
	title.text = label
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	grid.add_child(title)

	var minus_button := Button.new()
	minus_button.text = "－"
	minus_button.custom_minimum_size = Vector2(56, 40)
	minus_button.pressed.connect(func() -> void:
		apply_delta.call(minus_delta)
	)
	grid.add_child(minus_button)

	var value_panel := PanelContainer.new()
	value_panel.custom_minimum_size = Vector2(140, 40)
	grid.add_child(value_panel)

	var value_label := Label.new()
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	value_label.add_theme_font_size_override("font_size", 18)
	value_label.modulate = Color(0.88, 0.95, 1.0)
	value_panel.add_child(value_label)
	stepper_value_labels[value_key] = value_label

	var plus_button := Button.new()
	plus_button.text = "＋"
	plus_button.custom_minimum_size = Vector2(56, 40)
	plus_button.pressed.connect(func() -> void:
		apply_delta.call(plus_delta)
	)
	grid.add_child(plus_button)


func _refresh_stepper_values(entry) -> void:
	if entry == null:
		for key in stepper_value_labels.keys():
			var label_node: Label = stepper_value_labels[key]
			if label_node != null:
				label_node.text = "-"
		return

	_set_stepper_value("pos_x", "%.0f" % float(entry.position.x))
	_set_stepper_value("pos_y", "%.0f" % float(entry.position.y))
	_set_stepper_value("disguise_strength", "%.2f" % float(entry.disguise_strength))
	_set_stepper_value("move_range", "%.1f" % float(entry.move_range))
	_set_stepper_value("move_speed", "%.2f" % float(entry.move_speed))
	_set_stepper_value("reveal_cycle_sec", "%.2f" % float(entry.reveal_cycle_sec))
	_set_stepper_value("reveal_window_sec", "%.2f" % float(entry.reveal_window_sec))
	_set_stepper_value("suspicion_tier", "%d" % int(entry.suspicion_tier))
	_set_stepper_value("search_signal_strength", "%.2f" % float(entry.search_signal_strength))


func _set_stepper_value(value_key: String, text_value: String) -> void:
	if not stepper_value_labels.has(value_key):
		return
	var label_node: Label = stepper_value_labels[value_key]
	if label_node == null:
		return
	label_node.text = text_value


func _apply_default_clue_preset() -> void:
	var entry = _get_selected_entry()
	if entry == null:
		return

	if str(entry.actor_kind) == "civilian":
		entry.suspicion_tier = 0
		entry.search_signal_strength = 0.0
		entry.clue_profile = PackedStringArray(["呼吸平稳", "肩线自然"])
		entry.false_clue_profile = PackedStringArray(["玻璃反光像红眼", "衣领短暂闪动"])
		entry.false_clue_cycle_sec = 3.6
		entry.false_clue_window_sec = 0.55
	else:
		match str(entry.behavior_type):
			"moving":
				entry.suspicion_tier = 2
				entry.search_signal_strength = 0.72
				entry.clue_profile = PackedStringArray(["移动节奏异常", "眼白偏红"])
			"weakpoint":
				entry.suspicion_tier = 2
				entry.search_signal_strength = 0.86
				entry.clue_profile = PackedStringArray(["胸口周期性鼓动", "目光发亮"])
			_:
				entry.suspicion_tier = 1
				entry.search_signal_strength = 0.55
				entry.clue_profile = PackedStringArray(["红眼反光", "肩线略歪"])

	_refresh_detail()
	feedback_label.text = "已套用默认线索预设（未保存）。"


func _save_level_config() -> void:
	if level_config == null:
		return

	var path := CoreGameState.get_level_config_path(level_id)
	var error := ResourceSaver.save(level_config, path)
	if error == OK:
		feedback_label.modulate = Color(0.72, 0.98, 0.82)
		feedback_label.text = "保存成功：%s" % path
	else:
		feedback_label.modulate = Color(1.0, 0.55, 0.55)
		feedback_label.text = "保存失败（错误码 %d）：%s" % [error, path]


func _apply_surface_panel_style(panel: PanelContainer, is_emphasis: bool) -> void:
	var style := StyleBoxFlat.new()
	style.corner_radius_top_left = 18
	style.corner_radius_top_right = 18
	style.corner_radius_bottom_left = 18
	style.corner_radius_bottom_right = 18
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.shadow_size = 6
	style.shadow_color = Color(0.01, 0.02, 0.04, 0.22)
	if is_emphasis:
		style.bg_color = Color(0.10, 0.18, 0.28, 0.94)
		style.border_color = Color(0.60, 0.78, 1.0, 0.34)
	else:
		style.bg_color = Color(0.08, 0.13, 0.19, 0.88)
		style.border_color = Color(0.44, 0.58, 0.74, 0.22)
	panel.add_theme_stylebox_override("panel", style)


func _apply_action_button_style(button: Button, tone: String) -> void:
	var normal := StyleBoxFlat.new()
	var hover := StyleBoxFlat.new()
	var pressed := StyleBoxFlat.new()
	var focus := StyleBoxFlat.new()
	var disabled := StyleBoxFlat.new()
	var border_color := Color(0.42, 0.56, 0.72, 0.55)
	var color := Color(0.10, 0.16, 0.23, 0.94)
	var hover_color := Color(0.15, 0.22, 0.31, 0.98)
	var pressed_color := Color(0.08, 0.13, 0.19, 0.98)
	var focus_color := Color(0.18, 0.28, 0.40, 1.0)
	var disabled_color := Color(0.09, 0.12, 0.16, 0.62)

	if tone == "primary":
		color = Color(0.18, 0.35, 0.70, 0.98)
		hover_color = Color(0.24, 0.42, 0.82, 1.0)
		pressed_color = Color(0.14, 0.29, 0.58, 1.0)
		focus_color = Color(0.28, 0.47, 0.88, 1.0)
		disabled_color = Color(0.14, 0.22, 0.34, 0.68)
		border_color = Color(0.66, 0.82, 1.0, 0.72)

	for stylebox in [normal, hover, pressed, focus, disabled]:
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
	disabled.bg_color = disabled_color

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", Color(0.94, 0.97, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_color_override("font_focus_color", Color(1, 1, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.72, 0.78, 0.86, 0.72))
	button.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.07, 0.96))
	button.add_theme_constant_override("outline_size", 3)
