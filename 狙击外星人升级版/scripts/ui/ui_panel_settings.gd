extends "res://scripts/ui/ui_safe_page.gd"

const MENU_KEY_ART := preload("res://assets_mvp_placeholder/ui/menu-key-art.jpg")
const LOADING_SCOPE_ART := preload("res://assets_mvp_placeholder/ui/loading-scope-art.jpg")
const SETTING_ORDER := [
	"camera_pan_speed_scale",
	"search_mouse_look_scale",
	"zoom_step_scale",
	"edge_pan_speed_scale",
	"hold_vignette_strength",
]

var summary_label: Label
var value_labels: Dictionary = {}
var reset_button: Button
var back_button: Button
var title_label: Label
var hint_label: Label


func _ready() -> void:
	_prepare_safe_ui_root()
	_build_ui()
	_finalize_safe_ui_tree()
	_refresh_ui()

func _unhandled_input(event: InputEvent) -> void:
	# 兼容桌面 Esc / 移动端返回键
	if event.is_action_pressed("ui_cancel"):
		RouteGuard.request_route("main_menu", "手感设置-Esc返回")


func _build_ui() -> void:
	var backdrop := TextureRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.texture = MENU_KEY_ART
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(backdrop)

	var tint := ColorRect.new()
	tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	tint.color = Color(0.02, 0.04, 0.06, 0.72)
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
	eyebrow.text = "操作校准终端"
	eyebrow.modulate = Color(0.90, 0.95, 1.0, 0.94)
	eyebrow.add_theme_font_size_override("font_size", 16)
	eyebrow.add_theme_constant_override("outline_size", 5)
	eyebrow.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.92))
	header_vbox.add_child(eyebrow)

	title_label = Label.new()
	title_label.text = "操作手感设置"
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_constant_override("outline_size", 7)
	title_label.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.94))
	header_vbox.add_child(title_label)

	var intro := Label.new()
	intro.text = "校准准星、缩放、边缘跟镜和暗角反馈。这里只开放少量手感参数，不改变目标速度、弱点窗口与误伤阈值。"
	intro.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	intro.modulate = Color(0.84, 0.90, 0.98)
	intro.add_theme_font_size_override("font_size", 15)
	intro.add_theme_constant_override("line_separation", 4)
	header_vbox.add_child(intro)

	hint_label = Label.new()
	hint_label.text = "设置项已直接进入下方滚动区，底部固定保留恢复默认与返回主页。"
	hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	hint_label.modulate = Color(0.96, 0.80, 0.42)
	hint_label.add_theme_font_size_override("font_size", 14)
	header_vbox.add_child(hint_label)

	var content_panel := PanelContainer.new()
	content_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_apply_surface_panel_style(content_panel, false)
	shell.add_child(content_panel)

	var content_margin := MarginContainer.new()
	content_margin.add_theme_constant_override("margin_left", 16)
	content_margin.add_theme_constant_override("margin_top", 16)
	content_margin.add_theme_constant_override("margin_right", 16)
	content_margin.add_theme_constant_override("margin_bottom", 16)
	content_panel.add_child(content_margin)

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_theme_constant_override("separation", 14)
	content_margin.add_child(vbox)

	var section_title := Label.new()
	section_title.text = "当前配置"
	section_title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(section_title)

	summary_label = Label.new()
	summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	summary_label.modulate = Color(0.80, 0.88, 0.97)
	vbox.add_child(summary_label)

	# 中间区域采用可滚动容器，避免内容变多后“返回主页”被挤出屏幕导致无法退回。
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(scroll)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)

	var rules: Dictionary = CoreGameState.get_player_feel_setting_rules()
	for setting_name in SETTING_ORDER:
		var rule: Dictionary = rules.get(setting_name, {})

		var row_panel := PanelContainer.new()
		_apply_surface_panel_style(row_panel, false)
		content.add_child(row_panel)

		var row_margin := MarginContainer.new()
		row_margin.add_theme_constant_override("margin_left", 12)
		row_margin.add_theme_constant_override("margin_top", 10)
		row_margin.add_theme_constant_override("margin_right", 12)
		row_margin.add_theme_constant_override("margin_bottom", 10)
		row_panel.add_child(row_margin)

		var row_vbox := VBoxContainer.new()
		row_vbox.add_theme_constant_override("separation", 8)
		row_margin.add_child(row_vbox)

		var setting_title_label := Label.new()
		setting_title_label.text = str(rule.get("label", setting_name))
		setting_title_label.add_theme_font_size_override("font_size", 20)
		row_vbox.add_child(setting_title_label)

		var desc_label := Label.new()
		desc_label.text = str(rule.get("description", ""))
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_label.modulate = Color(0.72, 0.80, 0.90)
		row_vbox.add_child(desc_label)

		var action_row := HBoxContainer.new()
		action_row.add_theme_constant_override("separation", 10)
		row_vbox.add_child(action_row)

		var minus_button := Button.new()
		minus_button.text = "－"
		minus_button.custom_minimum_size = Vector2(72, 46)
		minus_button.add_theme_font_size_override("font_size", 24)
		minus_button.pressed.connect(func() -> void:
			_step_setting(setting_name, -1)
		)
		_apply_action_button_style(minus_button, "danger")
		action_row.add_child(minus_button)

		var value_label := Label.new()
		value_label.custom_minimum_size = Vector2(180, 42)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		action_row.add_child(value_label)
		value_labels[setting_name] = value_label

		var plus_button := Button.new()
		plus_button.text = "＋"
		plus_button.custom_minimum_size = Vector2(72, 46)
		plus_button.add_theme_font_size_override("font_size", 24)
		plus_button.pressed.connect(func() -> void:
			_step_setting(setting_name, 1)
		)
		_apply_action_button_style(plus_button, "positive")
		action_row.add_child(plus_button)

	_add_cycle_setting_row(
		content,
		"准星样式",
		"切换后会影响战斗界面的准星与瞄准镜中心样式。",
		"crosshair_style",
		func() -> void:
			CoreGameState.cycle_crosshair_style()
			_refresh_ui()
	)

	_add_cycle_setting_row(
		content,
		"准星颜色",
		"调整准星颜色以适配不同屏幕与背景。",
		"crosshair_color",
		func() -> void:
			CoreGameState.cycle_crosshair_color()
			_refresh_ui()
	)

	# 底部固定操作区：始终可见，避免“只能滚到最底部才能退出”的问题。
	var bottom_actions := HBoxContainer.new()
	bottom_actions.add_theme_constant_override("separation", 10)
	vbox.add_child(bottom_actions)

	reset_button = Button.new()
	reset_button.text = "恢复默认手感"
	reset_button.custom_minimum_size = Vector2(0, 54)
	reset_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	reset_button.pressed.connect(func() -> void:
		CoreGameState.reset_player_feel_settings()
		_refresh_ui()
	)
	_apply_action_button_style(reset_button, "danger")
	bottom_actions.add_child(reset_button)

	back_button = Button.new()
	back_button.text = "返回主页"
	back_button.custom_minimum_size = Vector2(0, 54)
	back_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_button.pressed.connect(func() -> void:
		RouteGuard.request_route("main_menu", "手感设置-返回主页")
	)
	_apply_action_button_style(back_button, "secondary")
	bottom_actions.add_child(back_button)


func _step_setting(setting_name: String, direction: int) -> void:
	var rules: Dictionary = CoreGameState.get_player_feel_setting_rules()
	var values: Dictionary = CoreGameState.get_player_feel_settings()
	var rule: Dictionary = rules.get(setting_name, {})
	var current_value: float = float(values.get(setting_name, 1.0))
	var step: float = float(rule.get("step", 0.1))
	CoreGameState.set_player_feel_setting(setting_name, current_value + float(direction) * step)
	_refresh_ui()


func _refresh_ui() -> void:
	var rules: Dictionary = CoreGameState.get_player_feel_setting_rules()
	var values: Dictionary = CoreGameState.get_player_feel_settings()
	summary_label.text = CoreGameState.build_player_feel_summary()

	for setting_name in SETTING_ORDER:
		if not value_labels.has(setting_name):
			continue

		var rule: Dictionary = rules.get(setting_name, {})
		var current_value: float = float(values.get(setting_name, 1.0))
		var min_value: float = float(rule.get("min", 0.0))
		var max_value: float = float(rule.get("max", 1.0))
		value_labels[setting_name].text = "%.2fx\n范围 %.2f - %.2f" % [
			current_value,
			min_value,
			max_value,
		]

	if value_labels.has("crosshair_style"):
		value_labels["crosshair_style"].text = _format_crosshair_style(str(values.get("crosshair_style", "plus")))

	if value_labels.has("crosshair_color"):
		var color_id := str(values.get("crosshair_color", "amber"))
		value_labels["crosshair_color"].text = _format_crosshair_color(color_id)
		value_labels["crosshair_color"].modulate = _resolve_crosshair_color(color_id)


func _add_cycle_setting_row(parent: VBoxContainer, title: String, desc: String, key: String, on_cycle: Callable) -> void:
	var row_panel := PanelContainer.new()
	_apply_surface_panel_style(row_panel, false)
	parent.add_child(row_panel)

	var row_margin := MarginContainer.new()
	row_margin.add_theme_constant_override("margin_left", 12)
	row_margin.add_theme_constant_override("margin_top", 10)
	row_margin.add_theme_constant_override("margin_right", 12)
	row_margin.add_theme_constant_override("margin_bottom", 10)
	row_panel.add_child(row_margin)

	var row_vbox := VBoxContainer.new()
	row_vbox.add_theme_constant_override("separation", 8)
	row_margin.add_child(row_vbox)

	var row_title_label := Label.new()
	row_title_label.text = title
	row_title_label.add_theme_font_size_override("font_size", 20)
	row_vbox.add_child(row_title_label)

	var desc_label := Label.new()
	desc_label.text = desc
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.modulate = Color(0.72, 0.80, 0.90)
	row_vbox.add_child(desc_label)

	var action_row := HBoxContainer.new()
	action_row.add_theme_constant_override("separation", 10)
	row_vbox.add_child(action_row)

	var cycle_button := Button.new()
	cycle_button.text = "切换"
	cycle_button.custom_minimum_size = Vector2(120, 42)
	cycle_button.pressed.connect(func() -> void:
		on_cycle.call()
	)
	_apply_action_button_style(cycle_button, "secondary")
	action_row.add_child(cycle_button)

	var value_label := Label.new()
	value_label.custom_minimum_size = Vector2(280, 42)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	action_row.add_child(value_label)
	value_labels[key] = value_label


func _format_crosshair_style(style_id: String) -> String:
	match style_id:
		"dot":
			return "点（•）"
		"circle":
			return "圆（○）"
		"x":
			return "叉（×）"
		"cross":
			return "十字（+）"
		_:
			return "粗十字（＋）"


func _format_crosshair_color(color_id: String) -> String:
	match color_id:
		"white":
			return "白色"
		"green":
			return "绿色"
		"red":
			return "红色"
		"cyan":
			return "青色"
		_:
			return "琥珀色"


func _resolve_crosshair_color(color_id: String) -> Color:
	match color_id:
		"white":
			return Color(1.0, 1.0, 1.0)
		"green":
			return Color(0.52, 1.0, 0.66)
		"red":
			return Color(1.0, 0.38, 0.38)
		"cyan":
			return Color(0.58, 0.92, 1.0)
		_:
			return Color(1.0, 0.95, 0.82)


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

	if tone == "danger":
		color = Color(0.28, 0.10, 0.12, 0.92)
		hover_color = Color(0.36, 0.12, 0.15, 0.98)
		pressed_color = Color(0.24, 0.08, 0.10, 0.98)
		focus_color = Color(0.42, 0.14, 0.18, 1.0)
		disabled_color = Color(0.16, 0.08, 0.09, 0.52)
		border_color = Color(1.0, 0.56, 0.58, 0.46)
	elif tone == "positive":
		color = Color(0.10, 0.34, 0.42, 0.96)
		hover_color = Color(0.14, 0.44, 0.54, 1.0)
		pressed_color = Color(0.08, 0.28, 0.36, 1.0)
		focus_color = Color(0.18, 0.52, 0.64, 1.0)
		disabled_color = Color(0.08, 0.18, 0.22, 0.54)
		border_color = Color(0.60, 0.92, 1.0, 0.60)
	elif tone == "secondary":
		color = Color(0.12, 0.20, 0.30, 0.94)
		hover_color = Color(0.16, 0.26, 0.38, 0.98)
		pressed_color = Color(0.10, 0.16, 0.24, 0.98)
		focus_color = Color(0.20, 0.32, 0.46, 1.0)
		disabled_color = Color(0.10, 0.14, 0.20, 0.56)
		border_color = Color(0.64, 0.80, 0.98, 0.44)

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
