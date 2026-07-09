extends "res://scripts/ui/ui_safe_page.gd"

const MENU_KEY_ART := preload("res://assets_mvp_placeholder/ui/menu-key-art.jpg")
const LOADING_SCOPE_ART := preload("res://assets_mvp_placeholder/ui/loading-scope-art.jpg")

var overview_label: Label
var continue_button: Button
var hero_status_label: Label
var side_summary_label: Label
var side_hint_label: Label
var display_mode_button: Button
var save_slot_dialog: Control

var ai_analysis_title: Label
var ai_analysis_comment: Label
var ai_analysis_tags: HBoxContainer
var ai_analysis_suggestion: Label
var ai_analysis_loading: Label
var ai_analysis_trend: Label


func _ready() -> void:
	_prepare_safe_ui_root()
	_build_ui()
	_finalize_safe_ui_tree()
	_enforce_safe_mouse_filter()
	_refresh_ui()
	if not PlatformService.display_mode_changed.is_connected(_on_display_mode_changed):
		PlatformService.display_mode_changed.connect(_on_display_mode_changed)
	_create_save_slot_dialog()


func _enforce_safe_mouse_filter() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	for child in get_children():
		if child is Button:
			continue
		if child is Control:
			var ctrl := child as Control
			ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			_enforce_children_ignore(ctrl)


func _enforce_children_ignore(node: Node) -> void:
	for child in node.get_children():
		if child is Button:
			continue
		if child is Control:
			var ctrl := child as Control
			ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_enforce_children_ignore(child)


func _build_ui() -> void:
	var backdrop := TextureRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.texture = MENU_KEY_ART
	backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	add_child(backdrop)

	var backdrop_tint := ColorRect.new()
	backdrop_tint.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop_tint.color = Color(0.02, 0.04, 0.06, 0.68)
	add_child(backdrop_tint)

	var top_glow := ColorRect.new()
	top_glow.anchor_left = 0.0
	top_glow.anchor_top = 0.0
	top_glow.anchor_right = 1.0
	top_glow.anchor_bottom = 0.24
	top_glow.color = Color(0.08, 0.15, 0.25, 0.28)
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

	var header_box := HBoxContainer.new()
	header_box.add_theme_constant_override("separation", 12)
	shell.add_child(header_box)

	var title_box := VBoxContainer.new()
	title_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_box.add_theme_constant_override("separation", 6)
	header_box.add_child(title_box)

	var title := Label.new()
	title.text = "狙击外星人 升级版"
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_constant_override("outline_size", 7)
	title.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.94))
	title_box.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "继续挑战、切换联机，或从第 1 关重新开始。"
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.modulate = Color(0.84, 0.90, 0.98)
	subtitle.add_theme_font_size_override("font_size", 15)
	subtitle.add_theme_constant_override("line_separation", 4)
	title_box.add_child(subtitle)

	var display_mode_button_vbox := VBoxContainer.new()
	display_mode_button_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	header_box.add_child(display_mode_button_vbox)

	display_mode_button = Button.new()
	display_mode_button.text = "显示：%s" % PlatformService.get_display_mode_name()
	display_mode_button.custom_minimum_size = Vector2(100, 34)
	display_mode_button.add_theme_font_size_override("font_size", 13)
	display_mode_button.add_theme_constant_override("outline_size", 3)
	display_mode_button.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.9))
	display_mode_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_apply_display_mode_button_style(display_mode_button)
	display_mode_button.pressed.connect(func() -> void:
		PlatformService.cycle_display_mode()
	)
	display_mode_button_vbox.add_child(display_mode_button)

	var uid_badge := Label.new()
	uid_badge.text = "UID 0742"
	uid_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	uid_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	uid_badge.custom_minimum_size = Vector2(116, 34)
	uid_badge.add_theme_font_size_override("font_size", 15)
	uid_badge.add_theme_constant_override("outline_size", 4)
	uid_badge.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.06, 0.9))
	uid_badge.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	_apply_label_badge_style(uid_badge)
	header_box.add_child(uid_badge)

	var summary_grid := GridContainer.new()
	summary_grid.columns = 1
	summary_grid.add_theme_constant_override("h_separation", 12)
	summary_grid.add_theme_constant_override("v_separation", 10)
	shell.add_child(summary_grid)

	var progress_card := _make_progress_card()
	progress_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	summary_grid.add_child(progress_card)

	var hero_panel := PanelContainer.new()
	shell.add_child(hero_panel)
	_apply_surface_panel_style(hero_panel, true)

	var hero_margin := MarginContainer.new()
	hero_margin.add_theme_constant_override("margin_left", 16)
	hero_margin.add_theme_constant_override("margin_top", 16)
	hero_margin.add_theme_constant_override("margin_right", 16)
	hero_margin.add_theme_constant_override("margin_bottom", 16)
	hero_panel.add_child(hero_margin)

	var hero_vbox := VBoxContainer.new()
	hero_vbox.add_theme_constant_override("separation", 8)
	hero_margin.add_child(hero_vbox)

	var hero_image := TextureRect.new()
	hero_image.texture = MENU_KEY_ART
	hero_image.custom_minimum_size = Vector2(0, 148)
	hero_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	hero_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	hero_vbox.add_child(hero_image)

	hero_status_label = Label.new()
	hero_status_label.modulate = Color(0.97, 0.80, 0.42)
	hero_status_label.add_theme_font_size_override("font_size", 14)
	hero_status_label.add_theme_constant_override("outline_size", 4)
	hero_status_label.add_theme_color_override("font_outline_color", Color(0.03, 0.05, 0.08, 0.9))
	hero_vbox.add_child(hero_status_label)

	side_summary_label = Label.new()
	side_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side_summary_label.modulate = Color(0.84, 0.90, 0.98)
	side_summary_label.add_theme_font_size_override("font_size", 13)
	side_summary_label.add_theme_constant_override("line_separation", 4)
	hero_vbox.add_child(side_summary_label)

	side_hint_label = Label.new()
	side_hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	side_hint_label.modulate = Color(0.96, 0.80, 0.42)
	side_hint_label.add_theme_font_size_override("font_size", 12)
	side_hint_label.add_theme_constant_override("line_separation", 4)
	hero_vbox.add_child(side_hint_label)

	var hero_actions := GridContainer.new()
	hero_actions.columns = 2
	hero_actions.add_theme_constant_override("h_separation", 8)
	hero_actions.add_theme_constant_override("v_separation", 8)
	hero_vbox.add_child(hero_actions)

	continue_button = _make_menu_button("继续当前关", "从上次离开的关卡继续战斗", true, 58)
	continue_button.pressed.connect(func() -> void:
		RouteGuard.request_route("level", "主菜单-继续验证", CoreGameState.current_level_id)
	)
	hero_actions.add_child(continue_button)

	var pvp_network_button := _make_menu_button("局域网对战（联机）", "加入联机对战", false, 56)
	pvp_network_button.pressed.connect(func() -> void:
		RouteGuard.request_route("pvp_lobby", "主菜单-局域网对战")
	)
	hero_actions.add_child(pvp_network_button)

	var start_first_button := _make_menu_button("从第1关开始", "从首关开启全新挑战", false, 52)
	start_first_button.pressed.connect(func() -> void:
		RouteGuard.request_route("level", "主菜单-第1关", 1)
	)
	hero_actions.add_child(start_first_button)

	var settings_button := _make_menu_button("操作手感设置", "调整准星、缩放与灵敏度", false, 52)
	settings_button.pressed.connect(func() -> void:
		RouteGuard.request_route("settings", "主菜单-手感设置")
	)
	hero_actions.add_child(settings_button)

	var lower_scroll := ScrollContainer.new()
	lower_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	shell.add_child(lower_scroll)

	var lower_content := VBoxContainer.new()
	lower_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lower_content.add_theme_constant_override("separation", 10)
	lower_scroll.add_child(lower_content)

	var feature_group := _make_button_group("作战准备", "查看与购买武器装备")
	lower_content.add_child(feature_group)
	var feature_buttons: VBoxContainer = feature_group.get_meta("button_box")

	var feature_grid := GridContainer.new()
	feature_grid.columns = 2
	feature_grid.add_theme_constant_override("h_separation", 8)
	feature_grid.add_theme_constant_override("v_separation", 8)
	feature_buttons.add_child(feature_grid)

	var weapon_library_button := _make_menu_button("武器库", "查看已解锁武器装备", false, 50)
	weapon_library_button.pressed.connect(func() -> void:
		RouteGuard.request_route("weapon_library", "主菜单-武器库")
	)
	feature_grid.add_child(weapon_library_button)

	var shop_button := _make_menu_button("商店", "购买武器、皮肤与道具", false, 50)
	shop_button.pressed.connect(func() -> void:
		RouteGuard.request_route("shop", "主菜单-商店")
	)
	feature_grid.add_child(shop_button)

	var test_center_button := _make_menu_button("测试中心", "运行烟雾测试与验证功能", false, 48, true)
	test_center_button.pressed.connect(func() -> void:
		RouteGuard.request_route("test_center", "主菜单-测试中心")
	)
	feature_grid.add_child(test_center_button)

	var tuning_button := _make_menu_button("关卡调参", "调整当前关卡的难度与参数", false, 48, true)
	tuning_button.pressed.connect(func() -> void:
		RouteGuard.request_route("tuning", "主菜单-调参面板")
	)
	feature_grid.add_child(tuning_button)

	var maintenance_group := _make_button_group("系统", "系统设置与存档管理")
	maintenance_group.modulate = Color(0.84, 0.88, 0.94, 0.88)
	lower_content.add_child(maintenance_group)
	var maintenance_buttons: VBoxContainer = maintenance_group.get_meta("button_box")

	var save_button := _make_menu_button("保存存档", "选择档位保存当前进度", false, 46, true)
	_apply_menu_button_style(save_button, "secondary")
	save_button.pressed.connect(func() -> void:
		save_slot_dialog.show_dialog("save", func(slot_index: int) -> void:
			CoreSaveService.save_to_slot(CoreGameState.build_save_payload(), slot_index)
			_refresh_ui()
		, func() -> void:
			pass
		)
	)
	maintenance_buttons.add_child(save_button)

	var load_button := _make_menu_button("读取存档", "选择档位恢复进度", false, 46, true)
	_apply_menu_button_style(load_button, "secondary")
	load_button.pressed.connect(func() -> void:
		save_slot_dialog.show_dialog("load", func(slot_index: int) -> void:
			var payload := CoreSaveService.load_from_slot(slot_index)
			if payload is Dictionary and not payload.is_empty():
				CoreGameState.restore_from_payload(payload)
			_refresh_ui()
		, func() -> void:
			pass
		)
	)
	maintenance_buttons.add_child(load_button)

	var reset_button := _make_menu_button("重置存档", "清空进度，重新开始", false, 46, true)
	_apply_menu_button_style(reset_button, "danger")
	reset_button.pressed.connect(func() -> void:
		CoreGameState.reset_progress()
		_refresh_ui()
	)
	maintenance_buttons.add_child(reset_button)

func _refresh_ui() -> void:
	var level_config: Variant = CoreGameState.get_level_config(CoreGameState.current_level_id)

	if display_mode_button != null and is_instance_valid(display_mode_button):
		display_mode_button.text = "显示：%s" % PlatformService.get_display_mode_name()

	hero_status_label.text = "当前任务：第 %d 关《%s》" % [
		CoreGameState.current_level_id,
		str(level_config.display_name),
	]

	overview_label.text = "已解锁：%d / %d\n当前金币：%d\n点击继续当前关卡" % [
		CoreGameState.unlocked_levels,
		CoreGameState.LEVEL_PATHS.size(),
		CoreGameState.player_gold,
	]

	side_summary_label.text = "作战准备就绪：继续闯关、联机对战，或访问武器库与商店。"
	side_hint_label.text = "提升战力：先升级武器再挑战。"

	continue_button.text = "继续当前关 · 第 %d 关《%s》" % [
		CoreGameState.current_level_id,
		str(level_config.display_name),
	]

	_request_ai_analysis()


func _request_ai_analysis() -> void:
	var records := CoreGameState.get_battle_history()
	if records.is_empty():
		ai_analysis_title.text = "AI 战术分析"
		ai_analysis_comment.text = "暂无战斗记录，完成几场战斗后再来查看AI分析吧！"
		ai_analysis_suggestion.text = ""
		ai_analysis_trend.text = ""
		_clear_tags()
		return

	var llm_service = get_node_or_null("/root/LLMService")
	if llm_service == null:
		_show_fallback_analysis(records)
		return

	if not llm_service.is_llm_enabled():
		_show_fallback_analysis(records)
		return

	ai_analysis_loading.visible = true
	ai_analysis_title.text = "AI 战术分析"

	if not llm_service.history_analysis_completed.is_connected(_on_ai_analysis_completed):
		llm_service.history_analysis_completed.connect(_on_ai_analysis_completed)
	if not llm_service.history_analysis_failed.is_connected(_on_ai_analysis_failed):
		llm_service.history_analysis_failed.connect(_on_ai_analysis_failed)

	llm_service.analyze_recent_battles(records)


func _on_ai_analysis_completed(result: Dictionary) -> void:
	ai_analysis_loading.visible = false
	_apply_ai_analysis_result(result)


func _on_ai_analysis_failed(error: String) -> void:
	ai_analysis_loading.visible = false
	var records := CoreGameState.get_battle_history()
	_show_fallback_analysis(records)


func _show_fallback_analysis(records: Array) -> void:
	var llm_service = get_node_or_null("/root/LLMService")
	if llm_service != null:
		var result = llm_service.get_fallback_history_analysis(records)
		_apply_ai_analysis_result(result)
	else:
		ai_analysis_title.text = "AI 战术分析"
		ai_analysis_comment.text = "共进行 %d 场战斗，继续加油！" % records.size()
		ai_analysis_suggestion.text = ""
		ai_analysis_trend.text = ""
		_clear_tags()


func _apply_ai_analysis_result(result: Dictionary) -> void:
	var title_text := str(result.get("title", ""))
	if not title_text.is_empty():
		ai_analysis_title.text = "AI 战术分析 · %s" % title_text
	else:
		ai_analysis_title.text = "AI 战术分析"

	var comment := str(result.get("overall_comment", ""))
	if comment.is_empty():
		comment = str(result.get("comment", ""))
	if not comment.is_empty():
		ai_analysis_comment.text = comment

	var suggestion := str(result.get("suggestion", ""))
	if not suggestion.is_empty():
		ai_analysis_suggestion.text = "💡 建议：%s" % suggestion
	else:
		ai_analysis_suggestion.text = ""

	var trend := str(result.get("trend", ""))
	if not trend.is_empty():
		ai_analysis_trend.text = "趋势：%s" % trend
		if trend == "上升":
			ai_analysis_trend.modulate = Color(0.62, 0.92, 0.62)
		elif trend == "下降":
			ai_analysis_trend.modulate = Color(0.96, 0.62, 0.62)
		else:
			ai_analysis_trend.modulate = Color(0.92, 0.82, 0.62)
	else:
		ai_analysis_trend.text = ""

	_clear_tags()
	var tags: Array = result.get("battle_tags", [])
	for tag in tags:
		_add_tag(str(tag))


func _clear_tags() -> void:
	for child in ai_analysis_tags.get_children():
		child.queue_free()


func _add_tag(tag_text: String) -> void:
	var tag_label := Label.new()
	tag_label.text = tag_text
	tag_label.modulate = Color(0.72, 0.86, 1.0)
	tag_label.add_theme_font_size_override("font_size", 12)
	tag_label.add_theme_constant_override("outline_size", 2)
	tag_label.add_theme_color_override("font_outline_color", Color(0.04, 0.08, 0.12, 0.9))

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.14, 0.22, 0.34, 0.88)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.52, 0.70, 0.92, 0.45)
	style.corner_radius_top_left = 10
	style.corner_radius_top_right = 10
	style.corner_radius_bottom_left = 10
	style.corner_radius_bottom_right = 10
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	tag_label.add_theme_stylebox_override("normal", style)

	ai_analysis_tags.add_child(tag_label)


func _make_progress_card() -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 220)
	_apply_surface_panel_style(panel, false)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title_row := HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	vbox.add_child(title_row)

	var title := Label.new()
	title.text = "当前进度"
	title.modulate = Color(0.96, 0.80, 0.42)
	title.add_theme_font_size_override("font_size", 16)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title_row.add_child(title)

	ai_analysis_trend = Label.new()
	ai_analysis_trend.text = ""
	ai_analysis_trend.modulate = Color(0.72, 0.92, 0.72)
	ai_analysis_trend.add_theme_font_size_override("font_size", 13)
	ai_analysis_trend.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	title_row.add_child(ai_analysis_trend)

	overview_label = Label.new()
	overview_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	overview_label.modulate = Color(0.90, 0.94, 0.98)
	overview_label.add_theme_font_size_override("font_size", 14)
	overview_label.add_theme_constant_override("line_separation", 3)
	vbox.add_child(overview_label)

	var divider := HSeparator.new()
	divider.modulate = Color(0.44, 0.58, 0.74, 0.3)
	vbox.add_child(divider)

	var ai_header := HBoxContainer.new()
	ai_header.add_theme_constant_override("separation", 8)
	vbox.add_child(ai_header)

	var ai_icon := Label.new()
	ai_icon.text = "🤖"
	ai_icon.add_theme_font_size_override("font_size", 14)
	ai_header.add_child(ai_icon)

	ai_analysis_title = Label.new()
	ai_analysis_title.text = "AI 战术分析"
	ai_analysis_title.modulate = Color(0.72, 0.86, 1.0)
	ai_analysis_title.add_theme_font_size_override("font_size", 14)
	ai_analysis_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ai_header.add_child(ai_analysis_title)

	ai_analysis_loading = Label.new()
	ai_analysis_loading.text = "分析中..."
	ai_analysis_loading.modulate = Color(0.72, 0.82, 0.92)
	ai_analysis_loading.add_theme_font_size_override("font_size", 12)
	ai_analysis_loading.visible = false
	ai_header.add_child(ai_analysis_loading)

	ai_analysis_tags = HBoxContainer.new()
	ai_analysis_tags.add_theme_constant_override("separation", 6)
	vbox.add_child(ai_analysis_tags)

	ai_analysis_comment = Label.new()
	ai_analysis_comment.text = "暂无战斗记录，完成几场战斗后再来查看AI分析吧！"
	ai_analysis_comment.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ai_analysis_comment.modulate = Color(0.84, 0.90, 0.98)
	ai_analysis_comment.add_theme_font_size_override("font_size", 13)
	ai_analysis_comment.add_theme_constant_override("line_separation", 3)
	vbox.add_child(ai_analysis_comment)

	ai_analysis_suggestion = Label.new()
	ai_analysis_suggestion.text = ""
	ai_analysis_suggestion.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	ai_analysis_suggestion.modulate = Color(0.97, 0.86, 0.56)
	ai_analysis_suggestion.add_theme_font_size_override("font_size", 13)
	ai_analysis_suggestion.add_theme_constant_override("line_separation", 3)
	vbox.add_child(ai_analysis_suggestion)

	return panel


func _make_info_card(title_text: String, minimum_size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = minimum_size
	_apply_surface_panel_style(panel, false)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = title_text
	title.modulate = Color(0.96, 0.80, 0.42)
	title.add_theme_font_size_override("font_size", 16)
	vbox.add_child(title)

	var body := Label.new()
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body.modulate = Color(0.90, 0.94, 0.98)
	body.add_theme_font_size_override("font_size", 15)
	body.add_theme_constant_override("line_separation", 4)
	vbox.add_child(body)

	panel.set_meta("body_label", body)
	return panel


func _on_display_mode_changed(_mode: String) -> void:
	if display_mode_button != null and is_instance_valid(display_mode_button):
		display_mode_button.text = "显示：%s" % PlatformService.get_display_mode_name()


func _apply_display_mode_button_style(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	var hover := StyleBoxFlat.new()
	var pressed := StyleBoxFlat.new()
	normal.bg_color = Color(0.10, 0.16, 0.23, 0.88)
	hover.bg_color = Color(0.15, 0.22, 0.31, 0.94)
	pressed.bg_color = Color(0.08, 0.13, 0.19, 0.94)
	for stylebox in [normal, hover, pressed]:
		stylebox.corner_radius_top_left = 14
		stylebox.corner_radius_top_right = 14
		stylebox.corner_radius_bottom_left = 14
		stylebox.corner_radius_bottom_right = 14
		stylebox.content_margin_left = 12
		stylebox.content_margin_right = 12
		stylebox.content_margin_top = 6
		stylebox.content_margin_bottom = 6
		stylebox.border_width_left = 1
		stylebox.border_width_top = 1
		stylebox.border_width_right = 1
		stylebox.border_width_bottom = 1
		stylebox.border_color = Color(0.42, 0.56, 0.72, 0.55)
		stylebox.shadow_color = Color(0.01, 0.02, 0.04, 0.22)
		stylebox.shadow_size = 4
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color(0.92, 0.96, 1.0))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))


func _apply_label_badge_style(label: Label) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.18, 0.26, 0.88)
	style.border_width_left = 1
	style.border_width_top = 1
	style.border_width_right = 1
	style.border_width_bottom = 1
	style.border_color = Color(0.63, 0.78, 1.0, 0.32)
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(0.01, 0.03, 0.05, 0.22)
	style.shadow_size = 4
	label.add_theme_stylebox_override("normal", style)


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


func _make_button_group(title_text: String, subtitle_text: String) -> PanelContainer:
	var panel := PanelContainer.new()

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	panel.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	margin.add_child(vbox)

	var title := Label.new()
	title.text = title_text
	title.add_theme_font_size_override("font_size", 19)
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = subtitle_text
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	subtitle.modulate = Color(0.76, 0.84, 0.92)
	subtitle.add_theme_font_size_override("font_size", 14)
	vbox.add_child(subtitle)

	var button_box := VBoxContainer.new()
	button_box.add_theme_constant_override("separation", 8)
	vbox.add_child(button_box)

	panel.set_meta("button_box", button_box)
	return panel


func _make_menu_button(title_text: String, hint_text: String, is_primary: bool, min_height: int, is_internal: bool = false) -> Button:
	var button := Button.new()
	button.text = "%s\n%s" % [title_text, hint_text]
	button.custom_minimum_size = Vector2(0, min_height)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 16 if is_primary else 15)
	button.add_theme_constant_override("line_separation", 4)
	if is_primary:
		button.modulate = Color(1.0, 0.96, 0.90)
	elif is_internal:
		button.modulate = Color(0.76, 0.82, 0.90, 0.72)
	else:
		button.modulate = Color(0.92, 0.96, 1.0)
	_apply_menu_button_style(button, "primary" if is_primary else ("internal" if is_internal else "secondary"))
	return button


func _apply_menu_button_style(button: Button, tone: String) -> void:
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
	var font_color := Color(0.94, 0.97, 1.0)
	var accent_color := Color(0.97, 0.80, 0.42)

	match tone:
		"primary":
			color = Color(0.18, 0.35, 0.70, 0.98)
			hover_color = Color(0.24, 0.42, 0.82, 1.0)
			pressed_color = Color(0.14, 0.29, 0.58, 1.0)
			focus_color = Color(0.28, 0.47, 0.88, 1.0)
			disabled_color = Color(0.14, 0.22, 0.34, 0.68)
			border_color = Color(0.66, 0.82, 1.0, 0.72)
		"internal":
			color = Color(0.12, 0.15, 0.20, 0.72)
			hover_color = Color(0.16, 0.20, 0.26, 0.82)
			pressed_color = Color(0.10, 0.13, 0.18, 0.86)
			focus_color = Color(0.18, 0.24, 0.33, 0.92)
			disabled_color = Color(0.09, 0.11, 0.15, 0.52)
			border_color = Color(0.48, 0.56, 0.66, 0.34)
			font_color = Color(0.82, 0.88, 0.96, 0.92)
			accent_color = Color(0.78, 0.84, 0.92)
		"danger":
			color = Color(0.28, 0.10, 0.12, 0.92)
			hover_color = Color(0.36, 0.12, 0.15, 0.98)
			pressed_color = Color(0.24, 0.08, 0.10, 0.98)
			focus_color = Color(0.42, 0.14, 0.18, 1.0)
			disabled_color = Color(0.16, 0.08, 0.09, 0.52)
			border_color = Color(1.0, 0.56, 0.58, 0.46)
			font_color = Color(1.0, 0.92, 0.92, 0.96)
			accent_color = Color(1.0, 0.74, 0.74)
		_:
			color = Color(0.10, 0.16, 0.23, 0.94)
			hover_color = Color(0.15, 0.22, 0.31, 0.98)
			pressed_color = Color(0.08, 0.13, 0.19, 0.98)
			focus_color = Color(0.18, 0.28, 0.40, 1.0)
			disabled_color = Color(0.09, 0.12, 0.16, 0.62)
			border_color = Color(0.42, 0.56, 0.72, 0.55)

	for stylebox in [normal, hover, pressed, focus, disabled]:
		stylebox.corner_radius_top_left = 18
		stylebox.corner_radius_top_right = 18
		stylebox.corner_radius_bottom_right = 18
		stylebox.corner_radius_bottom_left = 18
		stylebox.content_margin_left = 18
		stylebox.content_margin_right = 18
		stylebox.content_margin_top = 14
		stylebox.content_margin_bottom = 14
		stylebox.border_width_left = 1
		stylebox.border_width_top = 1
		stylebox.border_width_right = 1
		stylebox.border_width_bottom = 1
		stylebox.border_color = border_color
		stylebox.shadow_color = Color(0.01, 0.02, 0.04, 0.24)
		stylebox.shadow_size = 5

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
	button.add_theme_color_override("font_color", font_color)
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(1, 1, 1))
	button.add_theme_color_override("font_focus_color", Color(1, 1, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.72, 0.78, 0.86, 0.72))
	button.add_theme_color_override("font_outline_color", Color(0.02, 0.04, 0.07, 0.96))
	button.add_theme_constant_override("outline_size", 3)
	button.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.08, 0.36))
	button.add_theme_constant_override("shadow_offset_x", 0)
	button.add_theme_constant_override("shadow_offset_y", 1)
	button.add_theme_color_override("font_hover_pressed_color", accent_color)


func _create_save_slot_dialog() -> void:
	var dialog_script := preload("res://scripts/ui/ui_save_slot_dialog.gd")
	save_slot_dialog = Control.new()
	save_slot_dialog.set_script(dialog_script)
	save_slot_dialog.visible = false
	add_child(save_slot_dialog)
